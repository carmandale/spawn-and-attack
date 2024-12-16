import RealityKit
import Foundation

@MainActor
extension ADCMovementSystem {

    static func retargetADC(_ entity: Entity, 
                           _ adcComponent: inout ADCComponent,
                           currentPosition: SIMD3<Float>,
                           in scene: Scene) -> Bool {
        // Find new target
        guard let (newTarget, newCellID) = findNewTarget(for: entity, currentPosition: currentPosition, in: scene) else {
            print("⚠️ No valid targets found for retargeting")
            return false
        }
        
        print("🎯 Retargeting ADC to new cancer cell (ID: \(newCellID))")
        
        // Update component with new target
        adcComponent.targetEntityID = newTarget.id
        adcComponent.targetCellID = newCellID
        adcComponent.startWorldPosition = currentPosition  // Start from current position
        adcComponent.movementProgress = 0  // Reset progress for new path
        
        // Generate new random factors for variety
        adcComponent.speedFactor = Float.random(in: Self.speedRange)
        adcComponent.arcHeightFactor = Float.random(in: Self.arcHeightRange)
        
        // Mark the attachment point as occupied
        if var attachPoint = newTarget.components[AttachmentPoint.self] {
            attachPoint.isOccupied = true
            newTarget.components[AttachmentPoint.self] = attachPoint
            print("✅ Marked attachment point as occupied")
        }
        
        return true
    }

    static func validateTarget(_ targetEntity: Entity, _ adcComponent: ADCComponent, in scene: Scene) -> Bool {
        // Check if target entity still exists and is valid
        if targetEntity.parent == nil {
            print("⚠️ Target attachment point has been removed from scene")
            return false
        }
        
        // Check if parent cancer cell still exists
        guard let cancerCell = findParentCancerCell(for: targetEntity, in: scene) else {
            print("⚠️ Parent cancer cell no longer exists")
            return false
        }
        
        // Check if cancer cell is still valid (not being destroyed or dying)
        guard let cellComponent = cancerCell.components[CancerCellComponent.self],
              let cellID = adcComponent.targetCellID,
              cellComponent.cellID == cellID,
              !cellComponent.isDestroyed else {  // Only target alive cells
            print("⚠️ Cancer cell is no longer valid (destroyed or dying)")
            return false
        }
        
        return true
    }
    
    static func findNewTarget(for adcEntity: Entity, currentPosition: SIMD3<Float>, in scene: Scene) -> (Entity, Int)? {
        let cellQuery = EntityQuery(where: .has(CancerCellComponent.self))
        var closestDistance = Float.infinity
        var bestTarget: (attachPoint: Entity, cellID: Int)? = nil
        
        // Find all cancer cells
        for cellEntity in scene.performQuery(cellQuery) {
            guard let cellComponent = cellEntity.components[CancerCellComponent.self],
                  let cellID = cellComponent.cellID,
                  !cellComponent.isDestroyed else { continue }  // Only consider alive cells
            
            // Skip if cell is already at or past required hits
            if cellComponent.hitCount >= cellComponent.requiredHits {
                continue
            }
            
            // Find available attachment points recursively
            let attachmentPoints = findAttachmentPoints(in: cellEntity)
            
            for attachPoint in attachmentPoints {
                guard let attachComponent = attachPoint.components[AttachmentPoint.self],
                      !attachComponent.isOccupied else { continue }
                
                // Calculate distance to this attachment point
                let attachPosition = attachPoint.position(relativeTo: nil)
                let distance = length(attachPosition - currentPosition)
                
                // Update if this is the closest valid target
                if distance < closestDistance {
                    closestDistance = distance
                    bestTarget = (attachPoint: attachPoint, cellID: cellID)
                }
            }
        }
        
        return bestTarget
    }
    
    private static func findAttachmentPoints(in entity: Entity) -> [Entity] {
        var points: [Entity] = []
        
        // Check if this entity has an attachment point
        if entity.components[AttachmentPoint.self] != nil {
            points.append(entity)
        }
        
        // Recursively check children
        for child in entity.children {
            points.append(contentsOf: findAttachmentPoints(in: child))
        }
        
        return points
    }
}
