import RealityKit
import Foundation

/// A system that handles the curved path movement of ADC entities
@MainActor
public class ADCMovementSystem: System {
    /// Query to find entities that have an ADC component in moving state
    static let query = EntityQuery(where: .has(ADCComponent.self))
    
    // Movement parameters
    private static let numSteps: Double = 90  // Increased for smoother motion
    private static let baseArcHeight: Float = 1.2  // Slightly higher base arc
    private static let arcHeightRange: ClosedRange<Float> = 0.55...1.1  // More varied arcs
    private static let baseStepDuration: TimeInterval = 0.02  // Faster updates for smoother motion
    private static let speedRange: ClosedRange<Float> = 0.95...2.2  // Base speed range
    private static let spinSpeedRange: ClosedRange<Float> = 6.0...10.0  // More varied spin speeds
    private static let totalDuration: TimeInterval = numSteps * baseStepDuration
    private static let minDistance: Float = 0.5  // Minimum distance threshold
    private static let maxDistance: Float = 3.0  // Maximum distance threshold
    
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
                   let attachSound = audioComponent.resources["ADC_Attach.wav"] {
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
                
                // Calculate tangent vector (derivative of Bezier curve)
                let tangentStep1 = (controlPoint - start) * (1 - p)
                let tangentStep2 = (target - controlPoint) * p
                let tangent = normalize(2 * (tangentStep1 + tangentStep2))
                
                // Calculate up vector (trying to stay roughly upright while following curve)
                let up = SIMD3<Float>(0, 1, 0)
                let right = normalize(cross(tangent, up))
                let adjustedUp = cross(right, tangent)
                
                // Calculate banking angle
                let flatTangent = SIMD3<Float>(tangent.x, 0, tangent.z)
                let normalizedFlatTangent = normalize(flatTangent)
                let bankAngle = acos(dot(tangent, normalizedFlatTangent))
                
                // Determine bank direction
                let crossProduct = cross(normalizedFlatTangent, tangent)
                let bankSign: Float = crossProduct.y > 0 ? 1 : -1
                
                // Apply banking
                let maxBankAngle: Float = .pi / 6 // 30 degrees max bank
                let banking = simd_quatf(angle: bankAngle * bankSign * maxBankAngle, axis: tangent)
                
                // Create orientation that follows the curve
                let baseOrientation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: tangent)
                
                // Apply banking and smooth rotation
                let targetOrientation = banking * baseOrientation
                
                // Smoothly interpolate to target orientation
                let rotationSpeed: Float = 8.0 // Adjust for smoother or quicker rotation
                let currentOrientation = entity.orientation
                let slerpFactor = min(Float(context.deltaTime) * rotationSpeed, 1)
                entity.orientation = simd_slerp(currentOrientation, targetOrientation, slerpFactor)
                
                // Update position
                entity.position = position
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
        
        // Calculate distance-based speed adjustment
        let distance = length(targetPoint.position(relativeTo: nil) - start)
        let normalizedDistance = (distance - minDistance) / (maxDistance - minDistance)
        let clampedDistance = max(0, min(1, normalizedDistance))
        
        // For close distances, increase the minimum speed
        let adjustedSpeedRange = clampedDistance < 0.3 
            ? ClosedRange(uncheckedBounds: (lower: 1.5, upper: 2.0))  // Faster for close targets
            : speedRange
        
        adcComponent.speedFactor = Float.random(in: adjustedSpeedRange)
        
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
