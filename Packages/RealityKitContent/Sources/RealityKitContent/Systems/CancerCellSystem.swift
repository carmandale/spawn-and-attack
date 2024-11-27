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
            guard var component = entity.components[CancerCellComponent.self] else { continue }
            
            // Check for destruction first - highest priority
            if component.hitCount >= CancerCellComponent.requiredHits && !component.isDestroyed {
                // Mark as destroyed immediately
                component.isDestroyed = true
                entity.components[CancerCellComponent.self] = component
                
                print("=== Cancer Cell Death Triggered ===")
                
                // Play death animation immediately
                if let animLib = entity.components[AnimationLibraryComponent.self] {
                    if let deathAnimation = animLib.animations["death"] {
                        entity.playAnimation(deathAnimation)
                    }
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
                continue
            }
            
            // Handle sudden scale changes based on hit count
            if component.isScaling {
                let currentScale = entity.scale.x
                let targetScale = component.targetScale
                
                // Even faster scaling with easing
                let t = Float(15.0 * context.deltaTime) // 15x faster
                
                // Use exponential easing for more dramatic effect
                let easedT = 1.0 - pow(1.0 - t, 3)  // Cubic easing
                
                if abs(currentScale - targetScale) > 0.001 {
                    let newScale = simd_mix(currentScale, targetScale, easedT)
                    entity.scale = [newScale, newScale, newScale]
                } else {
                    // Animation complete
                    component.isScaling = false
                    entity.scale = [targetScale, targetScale, targetScale]
                }
                entity.components[CancerCellComponent.self] = component
            }
            
            // Check for hit count thresholds
            for threshold in CancerCellComponent.scaleThresholds {
                if component.hitCount == threshold.hits {
                    // Immediately start scaling down
                    component.isScaling = true
                    component.targetScale = threshold.scale
                    component.currentScale = threshold.scale
                    
                    entity.components[CancerCellComponent.self] = component
                    break
                }
            }
        }
    }
}
