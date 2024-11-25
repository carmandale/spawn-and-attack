import RealityKit

@MainActor
public class CancerCellSystem: System {
    /// Query for entities with CancerCell component
    static let query = EntityQuery(where: .has(CancerCellComponent.self))
    
    public required init(scene: Scene) {
        // One-time setup if needed
    }
    
    public func update(context: SceneUpdateContext) {
        // Will implement hit tracking and death animation triggering
    }
}
