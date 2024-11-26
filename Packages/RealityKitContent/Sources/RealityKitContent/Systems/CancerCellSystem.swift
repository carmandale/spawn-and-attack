import RealityKit
import Foundation

/// A system that manages cancer cell behavior
@MainActor
public class CancerCellSystem: System {
    /// Query for entities with CancerCell component
    static let query = EntityQuery(where: .has(CancerCellComponent.self))
    
    /// Initialize the system with the RealityKit scene
    public required init(scene: Scene) {}
    
    /// Update cancer cell entities
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var component = entity.components[CancerCellComponent.self] else { continue }
            
            // Check if cell should be destroyed
            if component.hitCount >= CancerCellComponent.requiredHits {
                entity.removeFromParent()
            }
        }
    }
}
