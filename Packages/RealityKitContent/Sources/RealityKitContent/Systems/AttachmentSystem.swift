import Foundation
import RealityKit
import SwiftUI

public struct AttachmentSystem: System {
    let attachmentQuery = EntityQuery(where: .has(AttachmentPoint.self))

    public init(scene: RealityKit.Scene) { }
    
    @MainActor
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: attachmentQuery, updatingSystemWhen: .rendering) {
            guard var attachPoint = entity.components[AttachmentPoint.self] else { continue }
            
            if attachPoint.pendingStateChange {
                attachPoint.pendingStateChange = false
                entity.components[AttachmentPoint.self] = attachPoint
            }
        }
    }
    
    // MARK: - Public API
    
    @MainActor
    public static func getAvailablePoint(in scene: RealityKit.Scene, isLeft: Bool) -> Entity? {
        let query = EntityQuery(where: .has(AttachmentPoint.self))
        let entities = scene.performQuery(query)
        
        return entities.first { entity in
            guard let attachPoint = entity.components[AttachmentPoint.self] else { return false }
            return !attachPoint.isOccupied && attachPoint.isLeft == isLeft
        }
    }
    
    @MainActor
    public static func markPointAsOccupied(_ entity: Entity) {
        guard var attachPoint = entity.components[AttachmentPoint.self] else { return }
        attachPoint.isOccupied = true
        attachPoint.pendingStateChange = true
        entity.components[AttachmentPoint.self] = attachPoint
    }
    
    @MainActor
    public static func markPointAsAvailable(_ entity: Entity) {
        guard var attachPoint = entity.components[AttachmentPoint.self] else { return }
        attachPoint.isOccupied = false
        attachPoint.pendingStateChange = true
        entity.components[AttachmentPoint.self] = attachPoint
    }
}
