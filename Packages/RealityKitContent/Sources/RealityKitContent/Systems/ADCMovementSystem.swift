import RealityKit
import Foundation

/// A system that handles the curved path movement of ADC entities
@MainActor
public class ADCMovementSystem: System {
    /// Query to find entities that have an ADC component in moving state
    static let query = EntityQuery(where: .has(ADCComponent.self))
    
    // Movement parameters
    private static let numSteps: Double = 60
    private static let baseArcHeight: Float = 1.0
    private static let arcHeightRange: ClosedRange<Float> = 0.65...1.0
    private static let baseStepDuration: TimeInterval = 0.03
    private static let speedRange: ClosedRange<Float> = 0.95...1.5
    private static let totalDuration: TimeInterval = numSteps * baseStepDuration
    
    /// Initialize the system with the RealityKit scene
    required public init(scene: Scene) {}
    
    /// Update the entities to apply movement
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var adcComponent = entity.components[ADCComponent.self],
                  adcComponent.state == .moving,
                  let start = adcComponent.startWorldPosition,
                  let targetID = adcComponent.targetEntityID else { continue }
            
            // Find target entity using ID
            let query = EntityQuery(where: .has(AttachmentPoint.self))
            let entities = context.scene.performQuery(query)
            guard let targetEntity = entities.first(where: { $0.id == Entity.ID(targetID) }) else { continue }
            
            // Get current target position
            let target = targetEntity.position(relativeTo: nil)
            
            // Use the randomized factors
            let speedFactor = adcComponent.speedFactor ?? 1.0
            let arcHeightFactor = adcComponent.arcHeightFactor ?? 1.0
            
            // Update progress with randomized speed
            adcComponent.movementProgress += Float(context.deltaTime / (Self.baseStepDuration * TimeInterval(1/speedFactor) * Self.numSteps))
            
            if adcComponent.movementProgress >= 1.0 {
                // Movement complete
                
                print("\n=== ADC Impact Debug ===")
                let impactDirection = normalize(target - start)
                print("Impact direction: \(impactDirection)")
                
                // Find the parent cancer cell using our utility function
                if let cancerCell = findParentCancerCell(for: targetEntity, in: context.scene),
                   var cellPhysics = cancerCell.components[PhysicsMotionComponent.self] {
                    print("Found cancer cell: \(cancerCell.name)")
                    print("Initial velocity: \(cellPhysics.linearVelocity)")
                    
                    // Apply impulse
                    cellPhysics.linearVelocity += impactDirection * 0.05
                    
                    // Add random angular velocity around Y axis
                    let randomSign: Float = Bool.random() ? 1.0 : -1.0
                    cellPhysics.angularVelocity += SIMD3<Float>(0, randomSign * 0.1, 0)
                    
                    print("New velocity: \(cellPhysics.linearVelocity)")
                    print("New angular velocity: \(cellPhysics.angularVelocity)")
                    
                    cancerCell.components[PhysicsMotionComponent.self] = cellPhysics
                    print("Updated physics on cancer cell")
                    
                } else {
                    print("Could not find parent cancer cell with physics component")
                }

                // Remove from current parent and add to target entity
                entity.removeFromParent()
                targetEntity.addChild(entity)
                
                // Align orientation with target and set position with slight offset
                entity.orientation = targetEntity.orientation(relativeTo: nil)
                entity.position = SIMD3<Float>(0, -0.08, 0)
                
                // Scale up animation
                var scaleUpTransform = entity.transform
                scaleUpTransform.scale = SIMD3<Float>(repeating: 1.2)
                
                // Animate scale up and back down
                entity.move(
                    to: scaleUpTransform,
                    relativeTo: entity.parent,
                    duration: 0.15,
                    timingFunction: .easeInOut
                )
                
                // After small delay, scale back to original
                Task {
                    try? await Task.sleep(for: .milliseconds(150))
                    var originalTransform = entity.transform
                    originalTransform.scale = SIMD3<Float>(repeating: 1.0)
                    
                    entity.move(
                        to: originalTransform,
                        relativeTo: entity.parent,
                        duration: 0.15,
                        timingFunction: .easeInOut
                    )
                }
                
                // Stop drone sound and play attach sound
                entity.stopAllAudio()
                if let audioComponent = entity.components[AudioLibraryComponent.self],
                   let attachSound = audioComponent.resources["Sonic_Pulse_Hit_01.wav"] {
                    entity.playAudio(attachSound)
                }
                
                // Update component state
                adcComponent.state = .attached
                entity.components[ADCComponent.self] = adcComponent
                
                // Increment hit count for target cell
                if let cellID = adcComponent.targetCellID {
                    let cellQuery = EntityQuery(where: .has(CancerCellComponent.self))
                    for cellEntity in context.scene.performQuery(cellQuery) {
                        guard let cellComponent = cellEntity.components[CancerCellComponent.self],
                              cellComponent.cellID == cellID else { continue }
                        
                        var updatedComponent = cellComponent
                        updatedComponent.hitCount += 1
                        cellEntity.components[CancerCellComponent.self] = updatedComponent
                        
                        // Update the AppModel's cancerCells array
                        NotificationCenter.default.post(
                            name: Notification.Name("UpdateCancerCell"),
                            object: nil,
                            userInfo: ["entity": cellEntity]
                        )
                        
                        print("Incremented hit count for cell \(cellID) to \(updatedComponent.hitCount)")
                        break
                    }
                }
            } else {
                // Calculate current position on curve using Bezier curve
                let p = adcComponent.movementProgress
                let distance = length(target - start)
                let midPoint = mix(start, target, t: 0.5)
                let heightOffset = distance * 0.5 * arcHeightFactor
                let controlPoint = midPoint + SIMD3<Float>(0, heightOffset, 0)
                
                // Quadratic Bezier formula: B(t) = (1-t)²P0 + 2(1-t)tP1 + t²P2
                let t1 = 1.0 - p
                let position = t1 * t1 * start + 2 * t1 * p * controlPoint + p * p * target
                
                // Update position
                entity.position = position
                
                // Apply rotation - spin around Z axis
                let rotationSpeed = adcComponent.spinSpeed ?? Float.random(in: 3.0...5.0)
                adcComponent.spinSpeed = rotationSpeed // Store for consistent speed
                
                let rotationAngle = rotationSpeed * Float(context.deltaTime)
                let rotation = simd_quatf(angle: rotationAngle, axis: [0, 0, 1])
                entity.orientation = entity.orientation * rotation
            }
            
            // Update component
            entity.components[ADCComponent.self] = adcComponent
        }
    }
    
    // MARK: - Public API
    
    @MainActor
    public static func startMovement(entity: Entity, from start: SIMD3<Float>, to targetPoint: Entity) {
        print("\n=== Starting ADC Movement ===")
        print("ADC Entity: \(entity.name)")
        print("Start Position: \(start)")
        print("Target Entity: \(targetPoint.name)")
        print("Target Position: \(targetPoint.position(relativeTo: nil))")
        print("ADC Components: \(entity.components)")
        
        guard var adcComponent = entity.components[ADCComponent.self] else {
            print("ERROR: No ADCComponent found on entity")
            return
        }
        
        // Set up movement
        adcComponent.state = .moving
        adcComponent.startWorldPosition = start
        adcComponent.movementProgress = 0
        adcComponent.targetEntityID = UInt64(targetPoint.id)
        adcComponent.spinSpeed = nil  // Will be set in first update
        
        // Add randomization factors
        adcComponent.arcHeightFactor = Float.random(in: arcHeightRange)
        adcComponent.speedFactor = Float.random(in: speedRange)
        
        // Update the component
        entity.components[ADCComponent.self] = adcComponent
        
        // Initial position
        entity.position = start
        
        // Start drone sound
        if let audioComponent = entity.components[AudioLibraryComponent.self],
           let droneSound = audioComponent.resources["Drones_01.wav"] {
            entity.playAudio(droneSound)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Finds the parent cancer cell entity for an attachment point by querying all cancer cells
    /// and checking if any are ancestors of the given entity
    private func findParentCancerCell(for attachmentPoint: Entity, in scene: Scene) -> Entity? {
        let cancerCellQuery = EntityQuery(where: .has(CancerCellComponent.self))
        let cancerCells = scene.performQuery(cancerCellQuery)
        
        // Check each cancer cell to see if it's an ancestor of our attachment point
        for cell in cancerCells {
            var current: Entity? = attachmentPoint
            while let parent = current?.parent {
                if parent == cell {
                    return parent
                }
                current = parent
            }
        }
        return nil
    }
}
