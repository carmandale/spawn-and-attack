import RealityKit
import Foundation

/// A system that handles ADC movement and targeting behavior
@MainActor
public final class ADCMovementSystem: System {
    // MARK: - Properties
    /// Query to find entities that have an ADC component in moving state
    static let query = EntityQuery(where: .has(ADCComponent.self))
    
    // Movement parameters
    private static let numSteps: Double = 120  // Increased for even smoother motion
    private static let baseArcHeight: Float = 1.2
    private static let arcHeightRange: ClosedRange<Float> = 0.6...1.2  // Slightly increased range
    private static let baseStepDuration: TimeInterval = 0.016  // ~60fps for smoother updates
    private static let speedRange: ClosedRange<Float> = 1.2...3.0  // Adjusted for more consistent speed
    private static let spinSpeedRange: ClosedRange<Float> = 4.0...8.0  // Reduced for smoother rotation
    private static let totalDuration: TimeInterval = numSteps * baseStepDuration
    private static let minDistance: Float = 0.5
    private static let maxDistance: Float = 3.0
    
    // Rotation parameters
    private static let rotationSmoothingFactor: Float = 12.0  // Increased for smoother rotation
    private static let maxBankAngle: Float = .pi / 8  // Reduced maximum banking angle
    private static let bankingSmoothingFactor: Float = 6.0  // New parameter for banking smoothing
    
    // Spin configuration
    private static let proteinSpinSpeed: Float = Float.random(in: 8.0...10.0)  // Random spin speed between 8-15
    private static let landingTransitionStart: Float = 0.85  // Start transition earlier
    
    // Acceleration parameters
    private static let accelerationPhase: Float = 0.2  // First 20% of movement
    private static let decelerationPhase: Float = 0.2  // Last 20% of movement
    private static let minSpeedMultiplier: Float = 0.4  // Minimum speed during accel/decel
    
    // MARK: - Configuration
    private static let baseSpeed: Float = 2.0
    private static let heightFactor: Float = 0.5
    private static let retargetingRotationSpeed: Float = 2.0
    private static let retargetInterval: TimeInterval = 1.0
    
    // Animation timing
    private static let scaleUpDuration: TimeInterval = 0.15
    private static let scaleDownDuration: TimeInterval = 0.15
    private static let scaleUpFactor: Float = 1.2
    
    // MARK: - Initialization
    required public init(scene: Scene) {}
    
    // MARK: - Public API
    @MainActor
    public static func startMovement(entity: Entity, from start: SIMD3<Float>, to targetPoint: Entity) {
        guard var adcComponent = entity.components[ADCComponent.self] else { return }
        
        // Update component with target information
        adcComponent.targetEntityID = targetPoint.id
        adcComponent.startWorldPosition = start
        adcComponent.targetWorldPosition = targetPoint.position(relativeTo: nil)
        
        // Reset movement state
        adcComponent.state = .moving
        adcComponent.movementProgress = 0
        adcComponent.needsRetarget = false
        
        // Apply the updated component
        entity.components[ADCComponent.self] = adcComponent
    }
    
    // MARK: - System Update
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var adcComponent = entity.components[ADCComponent.self],
                  adcComponent.state == .moving,
                  let start = adcComponent.startWorldPosition,
                  let targetID = adcComponent.targetEntityID else { continue }
            
            // Find target entity using ID
            let query = EntityQuery(where: .has(AttachmentPoint.self))
            let entities = context.scene.performQuery(query)
            guard let targetEntity = entities.first(where: { $0.id == Entity.ID(targetID) }) else {
                print("⚠️ Target entity not found - aborting ADC movement")
                adcComponent.state = .idle
                entity.components[ADCComponent.self] = adcComponent
                continue
            }
            
            // Validate target before proceeding
            if !validateTarget(targetEntity, adcComponent, in: context.scene) {
                print("⚠️ Target no longer valid - attempting to find new target")
                
                // Try to find new target
                if findAndSetNewTarget(entity: entity, 
                                     component: &adcComponent, 
                                     currentPosition: entity.position(relativeTo: nil),
                                     scene: context.scene) {
                    // Successfully retargeted - update component and continue
                    entity.components[ADCComponent.self] = adcComponent
                    continue
                } else {
                    // No valid targets found - reset ADC
                    print("⚠️ No valid targets found - resetting ADC")
                    resetADC(entity: entity, component: &adcComponent)
                    continue
                }
            }
            
            // Get current target position
            let target = targetEntity.position(relativeTo: nil)
            
            // Use the randomized factors
            let speedFactor = adcComponent.speed / baseSpeed
            let arcHeightFactor = 1.0  // Use constant for now
            
            // Calculate speed multiplier based on movement phase
            let speedMultiplier: Float
            if adcComponent.movementProgress < accelerationPhase {
                // Acceleration phase: gradually increase from minSpeedMultiplier to 1.0
                let t = adcComponent.movementProgress / accelerationPhase
                speedMultiplier = mix(minSpeedMultiplier, 1.0, t: smoothstep(0, 1, t))
            } else if adcComponent.movementProgress > (1.0 - decelerationPhase) {
                // Deceleration phase: gradually decrease from 1.0 to minSpeedMultiplier
                let t = (adcComponent.movementProgress - (1.0 - decelerationPhase)) / decelerationPhase
                speedMultiplier = mix(1.0, minSpeedMultiplier, t: smoothstep(0, 1, t))
            } else {
                // Cruising phase: full speed
                speedMultiplier = 1.0
            }
            
            // Update progress with randomized speed and phase-based multiplier
            adcComponent.movementProgress += Float(context.deltaTime / (baseStepDuration * TimeInterval(1/speedFactor) * numSteps)) * speedMultiplier
            
            if adcComponent.movementProgress >= 1.0 {
                // Movement complete
                handleImpact(entity: entity, component: &adcComponent)
            } else {
                // Calculate current position on curve using Bezier curve
                let p = adcComponent.movementProgress
                let distance = length(target - start)
                let midPoint = mix(start, target, t: 0.5)
                let height = distance * Float(heightFactor) * Float(arcHeightFactor)
                let controlPoint = midPoint + SIMD3<Float>(0, height, 0)
                
                // Calculate position on Bezier curve
                let pos1 = mix(start, controlPoint, t: p)
                let pos2 = mix(controlPoint, target, t: p)
                let currentPosition = mix(pos1, pos2, t: p)
                
                // Update entity position
                entity.position = currentPosition
                
                // Calculate and update orientation
                let direction = normalize(pos2 - pos1)
                if !direction.x.isNaN && !direction.y.isNaN && !direction.z.isNaN {
                    let up = SIMD3<Float>(0, 1, 0)
                    let rotation = simd_quatf(from: SIMD3<Float>(0, 0, -1), to: direction)
                    if validateQuaternion(rotation) {
                        entity.orientation = rotation
                    }
                }
            }
            
            // Apply updated component
            entity.components[ADCComponent.self] = adcComponent
            
            // Update protein spin
            updateProteinSpin(entity: entity, deltaTime: context.deltaTime)
        }
    }

    // MARK: - Helpers
    
    private func validateTarget(_ targetEntity: Entity, _ adcComponent: ADCComponent, in scene: Scene) -> Bool {
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
        
        // Check if cancer cell is still valid (not being destroyed)
        guard let cellComponent = cancerCell.components[CancerCellComponent.self],
              let cellID = adcComponent.targetCellID,
              cellComponent.cellID == cellID else {
            print("⚠️ Cancer cell component mismatch or missing")
            return false
        }
        
        return true
    }
    
    private func findParentCancerCell(for attachmentPoint: Entity, in scene: Scene) -> Entity? {
        let cancerCellQuery = EntityQuery(where: .has(CancerCellComponent.self))
        let cancerCells = scene.performQuery(cancerCellQuery)
        
        // Check each cancer cell to see if it's an ancestor of our attachment point
        for cell in cancerCells {
            var current: Entity? = attachmentPoint
            while let parent = current?.parent {
                if parent == cell {
                    return parent
                }
                current = parent
            }
        }
        return nil
    }
    
    private func findAndSetNewTarget(entity: Entity, 
                                   component: inout ADCComponent, 
                                   currentPosition: SIMD3<Float>,
                                   scene: Scene) -> Bool {
        // Find new target
        guard let (newTarget, newCellID) = findNewTarget(for: entity, currentPosition: currentPosition, in: scene) else {
            print("⚠️ No valid targets found for retargeting")
            return false
        }
        
        print("🎯 Retargeting ADC to new cancer cell (ID: \(newCellID))")
        
        // Update component with new target
        component.targetEntityID = newTarget.id
        component.targetCellID = newCellID
        component.startWorldPosition = currentPosition  // Start from current position
        component.movementProgress = 0  // Reset progress for new path
        
        // Generate new random factors for variety
        component.speedFactor = Float.random(in: Self.speedRange)
        component.arcHeightFactor = Float.random(in: Self.arcHeightRange)
        
        return true
    }
    
    private func resetADC(entity: Entity, component: inout ADCComponent) {
        component.state = .idle
        component.targetEntityID = nil
        component.targetCellID = nil
        component.movementProgress = 0
        entity.components[ADCComponent.self] = component
        
        // Stop any ongoing animations/audio
        entity.stopAllAnimations()
        entity.stopAllAudio()
    }
    
    private func handleImpact(entity: Entity, component: inout ADCComponent) {
        // Find target entity
        guard let targetID = component.targetEntityID,
              let scene = entity.scene else { return }
        
        let query = EntityQuery(where: .has(AttachmentPoint.self))
        guard let targetEntity = scene.performQuery(query).first(where: { $0.id == Entity.ID(targetID) }) else {
            print("⚠️ Target entity not found during impact")
            return
        }
        
        // Find parent cancer cell
        if let cancerCell = findParentCancerCell(for: targetEntity, in: scene) {
            // Update hit count on cancer cell
            if var cellComponent = cancerCell.components[CancerCellComponent.self] {
                cellComponent.hitCount += 1
                cancerCell.components[CancerCellComponent.self] = cellComponent
                
                // Post notification for UI update
                NotificationCenter.default.post(
                    name: Notification.Name("UpdateCancerCell"),
                    object: nil,
                    userInfo: ["entity": cancerCell]
                )
            }
        }
        
        // Remove from current parent and add to target entity
        entity.removeFromParent()
        targetEntity.addChild(entity)
        
        // Align orientation with target and set position with slight offset
        entity.orientation = targetEntity.orientation(relativeTo: nil)
        entity.position = SIMD3<Float>(0, -0.08, 0)
        
        // Scale up animation
        var scaleUpTransform = entity.transform
        scaleUpTransform.scale = SIMD3<Float>(repeating: 1.2)
        
        // Animate scale up and back down
        entity.move(
            to: scaleUpTransform,
            relativeTo: entity.parent,
            duration: 0.15,
            timingFunction: .easeInOut
        )
        
        // After small delay, scale back to original
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            var originalTransform = entity.transform
            originalTransform.scale = SIMD3<Float>(repeating: 1.0)
            
            entity.move(
                to: originalTransform,
                relativeTo: entity.parent,
                duration: 0.15,
                timingFunction: .easeInOut
            )
        }
        
        // Stop drone sound and play attach sound
        entity.stopAllAudio()
        if let audioComponent = entity.components[AudioLibraryComponent.self],
           let attachSound = audioComponent.resources["ADC_Attach.wav"] {
            entity.playAudio(attachSound)
        }
        
        // Update component state
        component.state = .attached
        entity.components[ADCComponent.self] = component
        
        // Increment hit count for target cell
        if let cellID = component.targetCellID {
            updateCancerCellHitCount(cellID: cellID, scene: scene)
        }
    }
    
    private func updateCancerCellHitCount(cellID: Int, scene: Scene) {
        let cellQuery = EntityQuery(where: .has(CancerCellComponent.self))
        for cellEntity in scene.performQuery(cellQuery) {
            guard let cellComponent = cellEntity.components[CancerCellComponent.self],
                  cellComponent.cellID == cellID else { continue }
            
            var updatedComponent = cellComponent
            updatedComponent.hitCount += 1
            cellEntity.components[CancerCellComponent.self] = updatedComponent
            
            NotificationCenter.default.post(
                name: Notification.Name("UpdateCancerCell"),
                object: nil,
                userInfo: ["entity": cellEntity]
            )
            break
        }
    }
    
    // MARK: - Math Helpers
    
    private func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        return a * (1 - t) + b * t
    }
    
    private func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        return a * (1 - t) + b * t
    }
    
    private func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = max(0, min((x - edge0) / (edge1 - edge0), 1))
        return t * t * (3 - 2 * t)
    }
    
    private func normalize(_ vector: SIMD3<Float>) -> SIMD3<Float> {
        let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        return length > 0 ? vector / length : vector
    }
    
    private func length(_ vector: SIMD3<Float>) -> Float {
        return sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    }
    
    private func updateProteinSpin(entity: Entity, deltaTime: TimeInterval) {
        if let proteinComplex = entity.findEntity(named: "antibodyProtein_complex") {
            let spinRotation = simd_quatf(angle: Float(deltaTime) * Self.proteinSpinSpeed, axis: [-1, 0, 0])
            proteinComplex.orientation = proteinComplex.orientation * spinRotation
        }
    }
}
