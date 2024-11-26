import RealityKit
import Foundation

/// A system that handles the curved path movement of ADC entities
@MainActor
public class ADCMovementSystem: System {
    /// Query to find entities that have an ADC component in moving state
    static let query = EntityQuery(where: .has(ADCComponent.self))
    
    // Movement parameters
    private static let numSteps: Double = 60
    private static let arcHeight: Float = 0.3
    private static let slalomWidth: Float = 0.2
    private static let stepDuration: TimeInterval = 0.03
    private static let totalDuration: TimeInterval = numSteps * stepDuration
    
    /// Initialize the system with the RealityKit scene
    required public init(scene: Scene) {}
    
    /// Update the entities to apply movement
    public func update(context: SceneUpdateContext) {
        // Get all entities with ADCComponent
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var adcComponent = entity.components[ADCComponent.self],
                  adcComponent.state == .moving,
                  let target = adcComponent.targetWorldPosition,
                  let start = adcComponent.startWorldPosition else { continue }
            
            // Update progress
            adcComponent.movementProgress += Float(context.deltaTime / Self.totalDuration)
            
            if adcComponent.movementProgress >= 1.0 {
                // Movement complete
                entity.position = target
                
                // Stop drone sound and play attach sound
                entity.stopAllAudio()
                if let audioComponent = entity.components[AudioLibraryComponent.self],
                   let attachSound = audioComponent.resources["Sonic_Pulse_Hit_01.wav"] {
                    entity.playAudio(attachSound)
                }
                
                // Update component state
                adcComponent.state = .attached
                entity.components[ADCComponent.self] = adcComponent
            } else {
                // Calculate current position on curve
                let p = adcComponent.movementProgress
                let basePoint = mix(start, target, t: p)
                let heightProgress = 1.0 - pow(p * 2.0 - 1.0, 2)
                let height = Self.arcHeight * heightProgress
                let sideOffset = sin(p * .pi * 1.5) * Self.slalomWidth * (1.0 - p)
                let position = basePoint + SIMD3<Float>(sideOffset, height, 0)
                
                // Update position
                entity.position = position
            }
            
            // Update component
            entity.components[ADCComponent.self] = adcComponent
        }
    }
    
    // MARK: - Public Methods
    
    /// Start movement for an ADC entity
    @MainActor
    public static func startMovement(entity: Entity, from start: SIMD3<Float>, to target: SIMD3<Float>) {
        guard var adcComponent = entity.components[ADCComponent.self] else { return }
        
        // Set up movement
        adcComponent.state = .moving
        adcComponent.startWorldPosition = start
        adcComponent.targetWorldPosition = target
        adcComponent.movementProgress = 0
        
        entity.components[ADCComponent.self] = adcComponent
        
        // Initial position
        entity.position = start
        
        // Start drone sound
        if let audioComponent = entity.components[AudioLibraryComponent.self],
           let droneSound = audioComponent.resources["Drones_01.wav"] {
            entity.playAudio(droneSound)
        }
    }
    
    // MARK: - Private Methods
    
    private func findParentWithComponent<T: Component>(_ componentType: T.Type, startingFrom entity: Entity) -> Entity? {
        var current: Entity? = entity
        while let parent = current?.parent {
            if parent.components[componentType] != nil {
                return parent
            }
            current = parent
        }
        return nil
    }
}
