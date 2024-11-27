import RealityKit
import Foundation

/// A system that manages cancer cell behavior
@MainActor
public class CancerCellSystem: System {
    /// Query for entities with CancerCell component
    static let query = EntityQuery(where: .has(CancerCellComponent.self))
    
    /// Cached audio resource
    private var destructionAudioResource: AudioFileResource?
    
    /// Initialize the system with the RealityKit scene
    public required init(scene: Scene) { }
    
    /// Update cancer cell entities
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let component = entity.components[CancerCellComponent.self] else { continue }
            
            // Check if cell should be destroyed
            if component.hitCount >= CancerCellComponent.requiredHits && !component.isDestroyed {
                // Mark as destroyed to prevent re-triggering
                if var updatedComponent = entity.components[CancerCellComponent.self] {
                    updatedComponent.isDestroyed = true
                    entity.components[CancerCellComponent.self] = updatedComponent
                }
                
                print("=== Cancer Cell Death Triggered ===")
                
                // Check for animation library
                if let animLib = entity.components[AnimationLibraryComponent.self] {
                    print("Found AnimationLibraryComponent on entity: \(entity.name)")
                    
                    // Print animation info
                    print("Number of animations: \(animLib.animations.count)")
                    print("Has animations: \(!animLib.animations.isEmpty)")
                    print("Default animation key: \(animLib.defaultKey ?? "none")")
                    
                    // Print all animation names
                    print("Animation names:")
                    for (name, _) in animLib.animations {
                        print("- \(name)")
                    }
                    
                    // Try to play death animation
                    if let deathAnimation = animLib.animations["death"] {
                        print("Found death animation")
                        print("Playing animation on entity: \(entity.name)")
                        entity.playAnimation(deathAnimation)
                    } else {
                        print("No death animation found in library")
                    }
                } else {
                    print("No AnimationLibraryComponent found on entity: \(entity.name)")
                }
                
                // Play audio
                if let audioComponent = entity.components[AudioLibraryComponent.self],
                   let deathSound = audioComponent.resources["Distortion_Wave_01.wav"] {
                    let controller = entity.playAudio(deathSound)
                    
                    // Remove after animation and audio completes
                    Task {
                        try? await Task.sleep(for: .seconds(2)) // Wait for animation
                        
                        // Create a continuation to wait for audio completion
                        await withCheckedContinuation { continuation in
                            controller.completionHandler = {
                                if entity.scene != nil {
                                    entity.removeFromParent()
                                }
                                continuation.resume()
                            }
                        }
                    }
                }
                
                // Remove after animation/audio completes
                // Task {
                //     try? await Task.sleep(for: .seconds(2))
                //     if entity.scene != nil {
                //         entity.removeFromParent()
                //     }
                // }
            }
        }
    }
}
