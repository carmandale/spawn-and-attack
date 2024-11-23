import RealityKit
import Foundation

#if DEBUG
@MainActor
class ADCTestHelper {
    static func createTestADC() -> Entity {
        let entity = Entity()
        
        // Add required components
        var stateComponent = ADCStateComponent()
        var behaviorComponent = ADCBehaviorComponent()
        
        // Configure test behavior
        behaviorComponent.speed = 2.0
        behaviorComponent.maxLifetime = 10.0
        
        // Add components to entity
        entity.components[ADCStateComponent.self] = stateComponent
        entity.components[ADCBehaviorComponent.self] = behaviorComponent
        
        return entity
    }
    
    static func createTestPath() -> [Transform] {
        // Create a simple circular path for testing
        let radius: Float = 0.5
        let steps = 20
        var keyframes: [Transform] = []
        
        for i in 0..<steps {
            let angle = Float(i) * (2 * .pi / Float(steps))
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            let position = SIMD3<Float>(x, y, 0)
            keyframes.append(Transform(scale: .one, rotation: simd_quatf(), translation: position))
        }
        
        return keyframes
    }
    
    static func runBasicTest(in scene: RealityKitScene) async -> Bool {
        // Create test entity
        let testEntity = createTestADC()
        scene.addEntity(testEntity)
        
        // Add test path
        var state = testEntity.components[ADCStateComponent.self]!
        state.pathKeyframes = createTestPath()
        testEntity.components[ADCStateComponent.self] = state
        
        // Create ADC system
        let adcSystem = ADCSystem(scene: scene)
        
        // Run system for a few frames
        for _ in 0..<10 {
            let context = SceneUpdateContext(deltaTime: 1.0/60.0)
            adcSystem.update(context: context)
            await Task.yield() // Allow other tasks to run
        }
        
        // Verify entity state
        guard let finalState = testEntity.components[ADCStateComponent.self] else {
            print("❌ Test failed: Entity lost state component")
            return false
        }
        
        // Check if entity moved along path
        if finalState.pathProgress <= 0 {
            print("❌ Test failed: Entity did not move along path")
            return false
        }
        
        print("✅ Basic ADC test passed")
        return true
    }
}
#endif
