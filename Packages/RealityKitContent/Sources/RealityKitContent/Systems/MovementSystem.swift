import RealityKit

/// A system that handles the movement and rotation of entities with MovementComponent
@MainActor
public class MovementSystem: System {
    /// Query to find entities that have a MovementComponent
    static let query = EntityQuery(where: .has(MovementComponent.self))
    
    /// Initialize the system with the RealityKit scene
    required public init(scene: Scene) {}
    
    /// Update the entities to apply movement and rotation
    public func update(context: SceneUpdateContext) {
        // Iterate over entities that match the query and are currently rendering
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            // Get the MovementComponent from the entity
            var comp = entity.components[MovementComponent.self]!
            
            // Update the time as it passes
            comp.time += context.deltaTime
            
            // Update the component in the entity
            entity.components[MovementComponent.self] = comp
            
            // Convert array to SIMD3 for rotation calculation
            let axis = SIMD3<Float>(comp.axis[0], comp.axis[1], comp.axis[2])
            
            // Adjust the orientation to update the angle, speed, and axis of rotation
            entity.setOrientation(simd_quatf(angle: Float(0.1 * comp.speed), axis: axis), relativeTo: entity)
        }
    }
}
