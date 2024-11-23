import Foundation
import RealityKit
import SwiftUI

@MainActor
public final class AttachmentSystem: System {
    /// Query for entities that have both the Reality Composer Pro component and the runtime state component
    static let query = EntityQuery(where: .has(AttachmentComponent.self) && .has(AttachmentStateComponent.self))
    
    public init(scene: RealityKit.Scene) { }
    
    public func update(context: SceneUpdateContext) {
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        for entity in entities {
            guard let stateComponent = entity.components[AttachmentStateComponent.self] else { continue }
            
            // Update the entity's state if needed
            if stateComponent.lastInteractionTime != 0 {
                // Update state based on interaction time
            }
        }
    }
    
    // MARK: - Public API
    
    public static func getAvailablePoint(in scene: RealityKit.Scene, isLeft: Bool) -> Entity? {
        print("[AttachmentSystem] Looking for \(isLeft ? "left" : "right") attachment point")
        let entities = scene.performQuery(query).filter { entity in
            guard let stateComponent = entity.components[AttachmentStateComponent.self] else {
                print("[AttachmentSystem] Warning: Entity missing AttachmentStateComponent")
                return false
            }
            let available = !stateComponent.isOccupied && stateComponent.isLeft == isLeft
            print("[AttachmentSystem] Point \(entity.name): occupied=\(stateComponent.isOccupied), isLeft=\(stateComponent.isLeft), available=\(available)")
            return available
        }
        print("[AttachmentSystem] Found \(entities.count) available attachment points")
        return entities.first
    }
    
    public static func markPointAsOccupied(_ entity: Entity, connectedEntity: Entity) {
        print("[AttachmentSystem] Marking point \(entity.name) as occupied by \(connectedEntity.name)")
        guard var stateComponent = entity.components[AttachmentStateComponent.self] else {
            print("[AttachmentSystem] Warning: Cannot mark point as occupied - missing AttachmentStateComponent")
            return
        }
        stateComponent.isOccupied = true
        stateComponent.lastInteractionTime = CACurrentMediaTime()
        stateComponent.connectedEntity = connectedEntity
        entity.components[AttachmentStateComponent.self] = stateComponent
        print("[AttachmentSystem] Successfully marked point as occupied")
    }
    
    public static func markPointAsAvailable(_ entity: Entity) {
        print("[AttachmentSystem] Marking point \(entity.name) as available")
        guard var stateComponent = entity.components[AttachmentStateComponent.self] else {
            print("[AttachmentSystem] Warning: Cannot mark point as available - missing AttachmentStateComponent")
            return
        }
        stateComponent.isOccupied = false
        stateComponent.lastInteractionTime = CACurrentMediaTime()
        stateComponent.connectedEntity = nil
        entity.components[AttachmentStateComponent.self] = stateComponent
        print("[AttachmentSystem] Successfully marked point as available")
    }
}
