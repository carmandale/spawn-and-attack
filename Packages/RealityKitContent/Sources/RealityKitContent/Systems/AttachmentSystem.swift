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
        // System now only monitors attachment points
        // State changes are handled directly in markPointAsOccupied/Available
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
        
        // Update parent cancer cell's hit count
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
