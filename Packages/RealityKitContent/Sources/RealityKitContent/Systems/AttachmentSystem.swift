import Foundation
import RealityKit
import SwiftUI

public struct AttachmentSystem: System {
    // Queries as instance properties to avoid concurrency issues
    let attachmentQuery = EntityQuery(where: .has(AttachmentPoint.self))
    let cancerCellQuery = EntityQuery(where: .has(CancerCellComponent.self))

    public init(scene: RealityKit.Scene) { }
    
    @MainActor
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.attachmentQuery, updatingSystemWhen: .rendering) {
            // if you find attachments, and they have marked themselves as occupied, then increment the hitCount of that attachments parent cancer cell. only one increment per isOccupied
            // if entity.components[AttachmentPoint.self]?.isOccupied == true {
            //     if let cellEntity = entity.parent,
            //        var cellComponent = cellEntity.components[CancerCellComponent.self] {
            //         cellComponent.hitCount += 1
            //         cellEntity.components[CancerCellComponent.self] = cellComponent
            //     }
            // }
        }
    }
    
    // MARK: - Public API
    
    @MainActor
    public static func getAvailablePoint(in scene: RealityKit.Scene, nearPosition: SIMD3<Float>) -> Entity? {
        // Create query locally since this is a static method
        let query = EntityQuery(where: .has(AttachmentPoint.self))
        let entities = scene.performQuery(query)
        
        // Find the closest unoccupied attachment point
        var closestPoint: Entity?
        var closestDistance: Float = .infinity
        
        for entity in entities {
            guard let attachPoint = entity.components[AttachmentPoint.self],
                  !attachPoint.isOccupied else { continue }
            
            let distance = simd_distance(entity.position(relativeTo: nil), nearPosition)
            if distance < closestDistance {
                closestDistance = distance
                closestPoint = entity
            }
        }
        
        return closestPoint
    }
    
    @MainActor
    public static func markPointAsOccupied(_ entity: Entity) {
        guard var attachPoint = entity.components[AttachmentPoint.self] else { return }
        attachPoint.isOccupied = true
        entity.components[AttachmentPoint.self] = attachPoint
        
        // Update parent cancer cell's hit count. the parent cell is 4 levels up from the attachment point. 
        if let cellEntity = entity.parent,
           var cellComponent = cellEntity.components[CancerCellComponent.self] {
           cellComponent.hitCount += 1
            cellEntity.components[CancerCellComponent.self] = cellComponent
        }
    }
    
    @MainActor
    public static func markPointAsAvailable(_ entity: Entity) {
        guard var attachPoint = entity.components[AttachmentPoint.self] else { return }
        attachPoint.isOccupied = false
        entity.components[AttachmentPoint.self] = attachPoint
    }
}
