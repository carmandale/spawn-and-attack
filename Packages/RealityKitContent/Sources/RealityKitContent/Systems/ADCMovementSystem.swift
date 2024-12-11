import RealityKit
import Foundation

/// A system that handles the curved path movement of ADC entities
@MainActor
public class ADCMovementSystem: System {
    /// Query to find entities that have an ADC component in moving state
    static let query = EntityQuery(where: .has(ADCComponent.self))
    
    // Movement parameters
    private static let numSteps: Double = 120  // Increased for even smoother motion
    private static let baseArcHeight: Float = 1.2
    private static let arcHeightRange: ClosedRange<Float> = 0.6...1.2  // Slightly increased range
    private static let baseStepDuration: TimeInterval = 0.016  // ~60fps for smoother updates
    private static let speedRange: ClosedRange<Float> = 1.2...3.0  // Adjusted for more consistent speed
    private static let spinSpeedRange: ClosedRange<Float> = 4.0...8.0  // Reduced for smoother rotation
    private static let totalDuration: TimeInterval = numSteps * baseStepDuration
    private static let minDistance: Float = 0.5
    private static let maxDistance: Float = 3.0
    
    // Rotation parameters
    private static let rotationSmoothingFactor: Float = 12.0  // Increased for smoother rotation
    private static let maxBankAngle: Float = .pi / 8  // Reduced maximum banking angle
    private static let bankingSmoothingFactor: Float = 6.0  // New parameter for banking smoothing
    
    // Spin configuration
    private static let proteinSpinSpeed: Float = Float.random(in: 8.0...10.0)  // Random spin speed between 8-15
    private static let landingTransitionStart: Float = 0.85  // Start transition earlier
    
    // Helper functions for interpolation
    private static func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        return a * (1 - t) + b * t
    }
    
    private static func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        return a * (1 - t) + b * t
    }
    
    private static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = max(0, min((x - edge0) / (edge1 - edge0), 1))
        return t * t * (3 - 2 * t)
    }
    
    private static func calculateOrientation(progress: Float,
                                          direction: SIMD3<Float>,
                                          deltaTime: TimeInterval,
                                          currentOrientation: simd_quatf,
                                          entity: Entity) -> simd_quatf {
        // Set root to face movement direction
        let baseOrientation = simd_quatf(from: [0, 0, 1], to: direction)
        
        // Update protein complex spin in world space
        if let proteinComplex = entity.findEntity(named: "antibodyProtein_complex") {
            // Convert local X-axis to world space
            let worldSpinAxis = baseOrientation.act([-1, 0, 0])
            let spinRotation = simd_quatf(angle: Float(deltaTime) * proteinSpinSpeed, axis: worldSpinAxis)
            
            // Apply spin in world space
            proteinComplex.orientation = spinRotation * proteinComplex.orientation
        }
        
        return baseOrientation
    }
    
    // Acceleration parameters
    private static let accelerationPhase: Float = 0.2  // First 20% of movement
    private static let decelerationPhase: Float = 0.2  // Last 20% of movement
    private static let minSpeedMultiplier: Float = 0.4  // Minimum speed during accel/decel
    
    // Quaternion validation
    private static func validateQuaternion(_ quat: simd_quatf) -> Bool {
        // Check if any component is NaN
        if quat.vector.x.isNaN || quat.vector.y.isNaN || quat.vector.z.isNaN || quat.vector.w.isNaN {
            return false
        }
        // Check if quaternion is normalized (length ≈ 1)
        let length = sqrt(quat.vector.x * quat.vector.x + 
                        quat.vector.y * quat.vector.y + 
                        quat.vector.z * quat.vector.z + 
                        quat.vector.w * quat.vector.w)
        return abs(length - 1.0) < 0.001
    }
    
    // Debug logging functions
    private static func debugMovementState(entity: Entity, 
                                         progress: Float, 
                                         speedFactor: Float, 
                                         position: SIMD3<Float>, 
                                         target: SIMD3<Float>) {
        // print("\n🚀 === ADC Movement State ===")
        // print("⏱️ Progress: \(String(format: "%.2f", progress))")
        // print("💨 Speed Factor: \(String(format: "%.2f", speedFactor))")
        // print("📍 Current: (\(String(format: "%.2f, %.2f, %.2f", position.x, position.y, position.z)))")
        // print("🎯 Target: (\(String(format: "%.2f, %.2f, %.2f", target.x, target.y, target.z)))")
        
        // Movement phase
        if progress < Self.accelerationPhase {
            // print("🏃‍♂️ Phase: Acceleration")
        } else if progress > (1.0 - Self.decelerationPhase) {
            // print("🛑 Phase: Deceleration")
        } else {
            // print("✈️ Phase: Cruising")
        }
    }

    private static func debugRotationState(position: SIMD3<Float>,
                                         tangent: SIMD3<Float>,
                                         bankAngle: Float?,
                                         verticalComponent: Float,
                                         currentOrientation: simd_quatf,
                                         targetOrientation: simd_quatf) {
        // print("\n🔄 === Rotation State ===")
        // print("📍 Position: (\(String(format: "%.2f, %.2f, %.2f", position.x, position.y, position.z)))")
        // print("➡️ Direction: (\(String(format: "%.2f, %.2f, %.2f", tangent.x, tangent.y, tangent.z)))")
        if let bankAngle = bankAngle {
            // print("🛩️ Bank: \(String(format: "%.2f°", bankAngle * 180 / .pi))")
        }
        // print("⬆️ Vertical Component: \(String(format: "%.2f", verticalComponent))")
        
        // Quaternion validation
        if !validateQuaternion(currentOrientation) {
            // print("⚠️ Warning: Invalid current orientation quaternion")
        }
        if !validateQuaternion(targetOrientation) {
            // print("⚠️ Warning: Invalid target orientation quaternion")
        }
    }
    
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
            guard let targetEntity = entities.first(where: { $0.id == Entity.ID(targetID) }) else {
                print("⚠️ Target entity not found - aborting ADC movement")
                adcComponent.state = .idle
                entity.components[ADCComponent.self] = adcComponent
                continue
            }
            
            // Validate target before proceeding
            if !Self.validateTarget(targetEntity, adcComponent, in: context.scene) {
                print("⚠️ Target no longer valid - attempting to find new target")
                
                // Try to find new target
                if Self.retargetADC(entity, 
                                  &adcComponent, 
                                  currentPosition: entity.position(relativeTo: nil),
                                  in: context.scene) {
                    // Successfully retargeted - update component and continue
                    entity.components[ADCComponent.self] = adcComponent
                    continue
                } else {
                    // No valid targets found - reset ADC
                    print("⚠️ No valid targets found - resetting ADC")
                    adcComponent.state = .idle
                    adcComponent.targetEntityID = nil
                    adcComponent.targetCellID = nil
                    adcComponent.movementProgress = 0
                    entity.components[ADCComponent.self] = adcComponent
                    
                    // Stop any ongoing animations/audio
                    entity.stopAllAnimations()
                    entity.stopAllAudio()
                    
                    continue
                }
            }
            
            // Get current target position
            let target = targetEntity.position(relativeTo: nil)
            
            // Use the randomized factors
            let speedFactor = adcComponent.speedFactor ?? 1.0
            let arcHeightFactor = adcComponent.arcHeightFactor ?? 1.0
            
            // Calculate speed multiplier based on movement phase
            let speedMultiplier: Float
            if adcComponent.movementProgress < Self.accelerationPhase {
                // Acceleration phase: gradually increase from minSpeedMultiplier to 1.0
                let t = adcComponent.movementProgress / Self.accelerationPhase
                speedMultiplier = Self.mix(Self.minSpeedMultiplier, 1.0, t: Self.smoothstep(0, 1, t))
                if Int(t * 100) % 50 == 0 { // Print at 0% and 50% of acceleration
                    // print("🏃‍♂️ Acceleration - Speed Multiplier: \(String(format: "%.2f", speedMultiplier))")
                }
            } else if adcComponent.movementProgress > (1.0 - Self.decelerationPhase) {
                // Deceleration phase: gradually decrease from 1.0 to minSpeedMultiplier
                let t = (adcComponent.movementProgress - (1.0 - Self.decelerationPhase)) / Self.decelerationPhase
                speedMultiplier = Self.mix(1.0, Self.minSpeedMultiplier, t: Self.smoothstep(0, 1, t))
                if Int(t * 100) % 50 == 0 { // Print at 0% and 50% of deceleration
                    // print("🛑 Deceleration - Speed Multiplier: \(String(format: "%.2f", speedMultiplier))")
                }
            } else {
                // Cruising phase: full speed
                speedMultiplier = 1.0
            }
            
            // Debug print for movement phase and speed (at key points)
            if Int(adcComponent.movementProgress * 100) % 25 == 0 { // Print at 0%, 25%, 50%, 75%
                // print("\n🚀 === ADC Progress [Entity: \(entity.name)] ===")
                // print("⏱️ Progress: \(String(format: "%.2f", adcComponent.movementProgress))")
                // print("💨 Speed Factor: \(String(format: "%.2f", speedFactor))")
                // print("🎚️ Speed Multiplier: \(String(format: "%.2f", speedMultiplier))")
            }
            
            // Update progress with randomized speed and phase-based multiplier
            adcComponent.movementProgress += Float(context.deltaTime / (Self.baseStepDuration * TimeInterval(1/speedFactor) * Self.numSteps)) * speedMultiplier
            
            if adcComponent.movementProgress >= 1.0 {
                // Movement complete
                print("\n=== ADC Impact ===")
                let impactDirection = normalize(target - start)
                // print("💥 Direction: (\(String(format: "%.2f, %.2f, %.2f", impactDirection.x, impactDirection.y, impactDirection.z)))")
                
                // Find the parent cancer cell using our utility function
                if let cancerCell = findParentCancerCell(for: targetEntity, in: context.scene),
                   var cellPhysics = cancerCell.components[PhysicsMotionComponent.self] {
                    // print("Found cancer cell: \(cancerCell.name)")
                    // print("Initial velocity: \(cellPhysics.linearVelocity)")
                    
                    // Apply impulse
                    cellPhysics.linearVelocity += impactDirection * 0.05
                    
                    // Add random angular velocity around Y axis
                    let randomSign: Float = Bool.random() ? 1.0 : -1.0
                    cellPhysics.angularVelocity += SIMD3<Float>(0, randomSign * 0.1, 0)
                    
                    // print("New velocity: \(cellPhysics.linearVelocity)")
                    // print("New angular velocity: \(cellPhysics.angularVelocity)")
                    
                    cancerCell.components[PhysicsMotionComponent.self] = cellPhysics
                    // print("Updated physics on cancer cell")
                    
                } else {
                    // print("Could not find parent cancer cell with physics component")
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
                let midPoint = Self.mix(start, target, t: 0.5)
                let heightOffset = distance * 0.5 * arcHeightFactor
                let controlPoint = midPoint + SIMD3<Float>(0, heightOffset, 0)
                
                // Quadratic Bezier formula: B(t) = (1-t)²P0 + 2(1-t)tP1 + t²P2
                let t1 = 1.0 - p
                let position = t1 * t1 * start + 2 * t1 * p * controlPoint + p * p * target
                
                // Update position
                entity.position = position
                
                // Set initial orientation only once when movement starts
                if adcComponent.movementProgress <= 0.01 {
                    let direction = normalize(target - start)
                    Self.setInitialRootOrientation(entity: entity, direction: direction)
                }
                
                // Update protein spin
                Self.updateProteinSpin(entity: entity, deltaTime: context.deltaTime)
                
                // Calculate tangent vector (derivative of Bezier curve)
                let tangentStep1 = (controlPoint - start) * (1 - p)
                let tangentStep2 = (target - controlPoint) * p
                let tangent = normalize(2 * (tangentStep1 + tangentStep2))
                
                // Debug prints every 10% progress
                if Int(adcComponent.movementProgress * 100) % 10 == 0 {
                    Self.debugMovementState(entity: entity,
                                         progress: adcComponent.movementProgress,
                                         speedFactor: speedFactor,
                                         position: position,
                                         target: target)
                    
                    // Calculate banking parameters
                    let flatTangent = SIMD3<Float>(tangent.x, 0, tangent.z)
                    let normalizedFlatTangent = normalize(flatTangent)
                    let crossProduct = cross(normalizedFlatTangent, tangent)
                    let verticalComponent = abs(tangent.y)
                    
                    Self.debugRotationState(position: position,
                                         tangent: tangent,
                                         bankAngle: adcComponent.currentBankAngle,
                                         verticalComponent: verticalComponent,
                                         currentOrientation: entity.orientation,
                                         targetOrientation: simd_quatf(from: SIMD3<Float>(0, 0, 1), to: tangent))
                }
                
                // Calculate and apply orientation with spin
                let orientation = Self.calculateOrientation(
                    progress: adcComponent.movementProgress,
                    direction: tangent,
                    deltaTime: context.deltaTime,
                    currentOrientation: entity.orientation,
                    entity: entity
                )
                entity.orientation = orientation
                
            }
            
            // Update component
            entity.components[ADCComponent.self] = adcComponent
        }
    }
    
    private static func setInitialRootOrientation(entity: Entity, direction: SIMD3<Float>) {
        let baseOrientation = simd_quatf(from: [0, 0, 1], to: direction)
        entity.orientation = baseOrientation
    }
    
    private static func updateProteinSpin(entity: Entity, deltaTime: TimeInterval) {
        if let proteinComplex = entity.findEntity(named: "antibodyProtein_complex") {
            let spinRotation = simd_quatf(angle: Float(deltaTime) * proteinSpinSpeed, axis: [-1, 0, 0])
            proteinComplex.orientation = proteinComplex.orientation * spinRotation
        }
    }
    
    private static func findParentCancerCell(for attachPoint: Entity, in scene: Scene) -> Entity? {
        var current = attachPoint
        while let parent = current.parent {
            if parent.components[CancerCellComponent.self] != nil {
                return parent
            }
            current = parent
        }
        return nil
    }
    
    private static func validateTarget(_ targetEntity: Entity, _ adcComponent: ADCComponent, in scene: Scene) -> Bool {
        // Check if target entity still exists and is valid
        if targetEntity.parent == nil {
            print("⚠️ Target attachment point has been removed from scene")
            return false
        }
        
        // Check if parent cancer cell still exists
        guard let cancerCell = findParentCancerCell(for: targetEntity, in: scene) else {
            print("⚠️ Parent cancer cell no longer exists")
            return false
        }
        
        // Check if cancer cell is still valid (not being destroyed)
        guard let cellComponent = cancerCell.components[CancerCellComponent.self],
              let cellID = adcComponent.targetCellID,
              cellComponent.cellID == cellID else {
            print("⚠️ Cancer cell component mismatch or missing")
            return false
        }
        
        return true
    }
    
    private static func findNewTarget(for adcEntity: Entity, currentPosition: SIMD3<Float>, in scene: Scene) -> (Entity, Int)? {
        let cellQuery = EntityQuery(where: .has(CancerCellComponent.self))
        var closestDistance = Float.infinity
        var bestTarget: (attachPoint: Entity, cellID: Int)? = nil
        
        // Find all cancer cells
        for cellEntity in scene.performQuery(cellQuery) {
            guard let cellComponent = cellEntity.components[CancerCellComponent.self],
                  let cellID = cellComponent.cellID else { continue }  // Skip cells without IDs
            
            // Skip if cell is already at or past required hits
            if cellComponent.hitCount >= cellComponent.requiredHits {
                continue
            }
            
            // Find available attachment points
            for child in cellEntity.children {
                guard child.components[AttachmentPoint.self] != nil,
                      child.components[ADCComponent.self] == nil else { continue }
                
                // Calculate distance to this attachment point
                let attachPosition = child.position(relativeTo: nil)
                let distance = length(attachPosition - currentPosition)
                
                // Update if this is the closest valid target
                if distance < closestDistance {
                    closestDistance = distance
                    bestTarget = (attachPoint: child, cellID: cellID)
                }
            }
        }
        
        return bestTarget
    }
    
    private static func retargetADC(_ entity: Entity, 
                                  _ adcComponent: inout ADCComponent,
                                  currentPosition: SIMD3<Float>,
                                  in scene: Scene) -> Bool {
        // Find new target
        guard let (newTarget, newCellID) = findNewTarget(for: entity, currentPosition: currentPosition, in: scene) else {
            print("⚠️ No valid targets found for retargeting")
            return false
        }
        
        print("🎯 Retargeting ADC to new cancer cell (ID: \(newCellID))")
        
        // Update component with new target
        adcComponent.targetEntityID = newTarget.id
        adcComponent.targetCellID = newCellID
        adcComponent.startWorldPosition = currentPosition  // Start from current position
        adcComponent.movementProgress = 0  // Reset progress for new path
        
        // Generate new random factors for variety
        adcComponent.speedFactor = Float.random(in: Self.speedRange)
        adcComponent.arcHeightFactor = Float.random(in: Self.arcHeightRange)
        
        return true
    }
    
    // MARK: - Public API
    
    @MainActor
    public static func startMovement(entity: Entity, from start: SIMD3<Float>, to targetPoint: Entity) {
        // print("\n=== Starting ADC Movement ===")
        // print("ADC Entity: \(entity.name)")
        // print("Start Position: \(start)")
        // print("Target Entity: \(targetPoint.name)")
        // print("Target Position: \(targetPoint.position(relativeTo: nil))")
        // print("ADC Components: \(entity.components)")
        
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
