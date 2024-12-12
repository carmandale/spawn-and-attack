import RealityKit
import Foundation

/// A system that handles the curved path movement of ADC entities
@MainActor
public class ADCMovementSystemBackup: System {
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
    
    // Movement phases
    private static let accelerationPhase: Float = 0.2  // First 20% of movement
    private static let decelerationPhase: Float = 0.2  // Last 20% of movement
    private static let minSpeedMultiplier: Float = 0.4  // Minimum speed during accel/decel
    
    // Retargeting parameters
    private static let retargetingSpeedMultiplier: Float = 0.3  // Speed while searching for new target
    private static let retargetingRotationSpeed: Float = 0.5  // How fast to rotate around the center while searching
    
    // Movement states
    private enum MovementState {
        case accelerating
        case cruising
        case decelerating
        case retargeting
        case arrived
    }
    
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
    
    /// Initialize the system with the RealityKit scene
    required public init(scene: Scene) {}
    
    /// Update the entities to apply movement
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let adcComponent = entity.components[ADCComponent.self],
                  adcComponent.state == .moving else { continue }
            
            // Create mutable copy
            var updatedComponent = adcComponent
            
            // Handle retargeting state
            if updatedComponent.needsRetarget {
                handleRetargetingMovement(entity: entity, component: &updatedComponent, deltaTime: context.deltaTime)
                entity.components[ADCComponent.self] = updatedComponent
                continue
            }
            
            // Normal movement handling
            guard let start = updatedComponent.startWorldPosition,
                  let targetID = updatedComponent.targetEntityID else { continue }
            
            // Find target entity using ID
            let query = EntityQuery(where: .has(AttachmentPoint.self))
            let entities = context.scene.performQuery(query)
            guard let targetEntity = entities.first(where: { $0.id == Entity.ID(targetID) }) else {
                print("⚠️ Target entity not found - entering retargeting state")
                updatedComponent.needsRetarget = true
                entity.components[ADCComponent.self] = updatedComponent
                continue
            }
            
            // Validate target before proceeding
            if !Self.validateTarget(targetEntity, updatedComponent, in: context.scene) {
                print("⚠️ Target no longer valid - attempting to find new target")
                
                // Try to find new target
                if Self.retargetADC(entity, 
                                  &updatedComponent, 
                                  currentPosition: entity.position(relativeTo: nil),
                                  in: context.scene) {
                    // Successfully retargeted - update component and continue
                    entity.components[ADCComponent.self] = updatedComponent
                    continue
                } else {
                    // No valid targets found - reset ADC
                    print("⚠️ No valid targets found - resetting ADC")
                    updatedComponent.state = .idle
                    updatedComponent.targetEntityID = nil
                    updatedComponent.targetCellID = nil
                    updatedComponent.movementProgress = 0
                    entity.components[ADCComponent.self] = updatedComponent
                    
                    // Stop any ongoing animations/audio
                    entity.stopAllAnimations()
                    entity.stopAllAudio()
                    
                    continue
                }
            }
            
            // Get current target position
            let target = targetEntity.position(relativeTo: nil)
            
            // Use the randomized factors
            let speedFactor = updatedComponent.speedFactor ?? 1.0
            let arcHeightFactor = updatedComponent.arcHeightFactor ?? 1.0
            
            // Calculate speed multiplier based on movement phase
            let speedMultiplier: Float
            if updatedComponent.movementProgress < Self.accelerationPhase {
                // Acceleration phase: gradually increase from minSpeedMultiplier to 1.0
                let t = updatedComponent.movementProgress / Self.accelerationPhase
                speedMultiplier = Self.mix(Self.minSpeedMultiplier, 1.0, t: Self.smoothstep(0, 1, t))
                if Int(t * 100) % 50 == 0 { // Print at 0% and 50% of acceleration
                    // print("🏃‍♂️ Acceleration - Speed Multiplier: \(String(format: "%.2f", speedMultiplier))")
                }
            } else if updatedComponent.movementProgress > (1.0 - Self.decelerationPhase) {
                // Deceleration phase: gradually decrease from 1.0 to minSpeedMultiplier
                let t = (updatedComponent.movementProgress - (1.0 - Self.decelerationPhase)) / Self.decelerationPhase
                speedMultiplier = Self.mix(1.0, Self.minSpeedMultiplier, t: Self.smoothstep(0, 1, t))
                if Int(t * 100) % 50 == 0 { // Print at 0% and 50% of deceleration
                    // print("🛑 Deceleration - Speed Multiplier: \(String(format: "%.2f", speedMultiplier))")
                }
            } else {
                // Cruising phase: full speed
                speedMultiplier = 1.0
            }
            
            // Debug print for movement phase and speed (at key points)
            if Int(updatedComponent.movementProgress * 100) % 25 == 0 { // Print at 0%, 25%, 50%, 75%
                // print("\n🚀 === ADC Progress [Entity: \(entity.name)] ===")
                // print("⏱️ Progress: \(String(format: "%.2f", updatedComponent.movementProgress))")
                // print("💨 Speed Factor: \(String(format: "%.2f", speedFactor))")
                // print("🎚️ Speed Multiplier: \(String(format: "%.2f", speedMultiplier))")
            }
            
            // Update progress with randomized speed and phase-based multiplier
            updatedComponent.movementProgress += Float(context.deltaTime / (Self.baseStepDuration * TimeInterval(1/speedFactor) * Self.numSteps)) * speedMultiplier
            
            if updatedComponent.movementProgress >= 1.0 {
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
                updatedComponent.state = .attached
                entity.components[ADCComponent.self] = updatedComponent
                
                // Increment hit count for target cell
                if let cellID = updatedComponent.targetCellID {
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
                let p = updatedComponent.movementProgress
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
                if updatedComponent.movementProgress <= 0.01 {
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
                if Int(updatedComponent.movementProgress * 100) % 10 == 0 {
                    Self.debugMovementState(entity: entity,
                                         progress: updatedComponent.movementProgress,
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
                                         bankAngle: updatedComponent.currentBankAngle,
                                         verticalComponent: verticalComponent,
                                         currentOrientation: entity.orientation,
                                         targetOrientation: simd_quatf(from: SIMD3<Float>(0, 0, 1), to: tangent))
                }
                
                // Calculate and apply orientation with spin
                let orientation = Self.calculateOrientation(
                    progress: updatedComponent.movementProgress,
                    direction: tangent,
                    deltaTime: context.deltaTime,
                    currentOrientation: entity.orientation,
                    entity: entity
                )
                entity.orientation = orientation
                
            }
            
            // Update the component with new values
            entity.components[ADCComponent.self] = updatedComponent
        }
    }
    
    private func handleRetargetingMovement(entity: Entity, component: inout ADCComponent, deltaTime: TimeInterval) {
        // Initialize or update elapsed time
        component.elapsedTime += deltaTime
        
        // Continue along current path while searching
        if let lastVelocity = component.currentVelocity {
            let center = SIMD3<Float>(0, 1.5, 0) // Center point where gravity is
            let currentPosition = entity.position(relativeTo: nil)
            
            // Calculate orbit rotation
            let toCenter = center - currentPosition
            let orbitAxis = simd_normalize(simd_cross(toCenter, [0, 1, 0]))
            let rotationAmount = Self.retargetingRotationSpeed * Float(deltaTime)
            let rotationMatrix = simd_matrix3x3(simd_quatf(angle: rotationAmount, axis: orbitAxis))
            
            // Apply rotation and continue movement with gradual slowdown
            let rotatedVelocity = rotationMatrix * lastVelocity
            let speedDecay = exp(-Float(component.elapsedTime) * 0.5) // Exponential decay
            let newVelocity = simd_normalize(rotatedVelocity) * (Self.speedRange.lowerBound * Self.retargetingSpeedMultiplier * speedDecay)
            
            entity.position += newVelocity * Float(deltaTime)
            component.currentVelocity = newVelocity
            
            // Update orientation to face movement direction
            let up = SIMD3<Float>(0, 1, 0)
            let lookAtPoint = entity.position + newVelocity
            entity.look(at: lookAtPoint, from: entity.position, relativeTo: nil)
            
            // Update protein spin during retargeting
            Self.updateProteinSpin(entity: entity, deltaTime: deltaTime)
        } else {
            // Initialize velocity if not set
            let initialSpeed = Self.speedRange.lowerBound * Self.retargetingSpeedMultiplier
            component.currentVelocity = SIMD3<Float>(1, 0, 0) * initialSpeed
        }
        
        // Set the retargeting flag
        component.needsRetarget = true
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
        // Find parent cancer cell
        var current = targetEntity
        while let parent = current.parent {
            if let cellComponent = parent.components[CancerCellComponent.self],
               let cellID = cellComponent.cellID,
               cellID == adcComponent.targetCellID {
                // Check if cell is dead (hit count >= required hits)
                return cellComponent.hitCount < cellComponent.requiredHits
            }
            current = parent
        }
        return false  // No valid parent cell found
    }
    
    private static func findNewTarget(for adcEntity: Entity, currentPosition: SIMD3<Float>, in scene: Scene) -> (Entity, Int)? {
        // Query for all attachment points
        let attachmentQuery = EntityQuery(where: .has(AttachmentPoint.self))
        var closestDistance = Float.infinity
        var bestTarget: (Entity, Int)? = nil
        
        // Find all attachment points
        for attachPoint in scene.performQuery(attachmentQuery) {
            guard let attachComponent = attachPoint.components[AttachmentPoint.self],
                  !attachComponent.isOccupied,
                  let cellID = attachComponent.cellID else { continue }
            
            // Calculate distance to this attachment point
            let attachPosition = attachPoint.position(relativeTo: nil)
            let distance = simd_length(attachPosition - currentPosition)
            
            // Update if this is the closest valid target
            if distance < closestDistance {
                closestDistance = distance
                bestTarget = (attachPoint, cellID)
            }
        }
        
        // Mark the chosen point as occupied
        if let (targetPoint, _) = bestTarget {
            AttachmentSystem.markPointAsOccupied(targetPoint)
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
    
    private static func updateADCMovement(_ adcEntity: Entity, _ adcComponent: inout ADCComponent, deltaTime: TimeInterval) {
        var movementState: MovementState = .cruising
        var speedMultiplier: Float = 1.0
        
        // Calculate progress based on component's base speed
        let speed = adcComponent.baseSpeed * (adcComponent.speedFactor ?? 1.0)
        let progress = Float(adcComponent.elapsedTime) / Float(adcComponent.totalTime)
        
        // Determine movement state and speed multiplier
        if adcComponent.targetEntity == nil {
            movementState = .retargeting
            speedMultiplier = Self.retargetingSpeedMultiplier
            
            // Continue along previous trajectory while rotating around center
            if let currentVelocity = adcComponent.currentVelocity {
                let center = SIMD3<Float>(0, 1.5, 0) // Center point where gravity is
                let currentPosition = adcEntity.position(relativeTo: nil)
                
                // Calculate orbit rotation
                let toCenter = center - currentPosition
                let orbitAxis = simd_normalize(simd_cross(toCenter, [0, 1, 0]))
                let rotationAmount = Self.retargetingRotationSpeed * Float(deltaTime)
                let rotationMatrix = simd_matrix3x3(simd_quatf(angle: rotationAmount, axis: orbitAxis))
                
                // Apply rotation and continue movement
                let rotatedVelocity = rotationMatrix * currentVelocity
                let newVelocity = simd_normalize(rotatedVelocity) * (Self.baseSpeed * speedMultiplier)
                
                adcEntity.position += newVelocity * Float(deltaTime)
                adcComponent.currentVelocity = newVelocity
            }
            return
        }
        
        // Normal movement phases
        if progress < Self.accelerationPhase {
            movementState = .accelerating
            speedMultiplier = Self.minSpeedMultiplier + (1.0 - Self.minSpeedMultiplier) * (progress / Self.accelerationPhase)
        } else if progress > (1.0 - Self.decelerationPhase) {
            movementState = .decelerating
            let decelerationProgress = (progress - (1.0 - Self.decelerationPhase)) / Self.decelerationPhase
            speedMultiplier = 1.0 - (1.0 - Self.minSpeedMultiplier) * decelerationProgress
        }
        
        // Update position
        if let targetPosition = adcComponent.targetEntity?.position(relativeTo: nil) {
            let currentPosition = adcEntity.position(relativeTo: nil)
            let direction = simd_normalize(targetPosition - currentPosition)
            let velocity = direction * (Self.baseSpeed * speedMultiplier)
            
            adcEntity.position += velocity * Float(deltaTime)
            adcComponent.currentVelocity = velocity
            
            // Update orientation
            let up = SIMD3<Float>(0, 1, 0)
            adcEntity.look(at: targetPosition, from: currentPosition, relativeTo: nil, up: up)
        }
    }
    
    // MARK: - Public API
    
    @MainActor
    public static func startMovement(entity: Entity, from start: SIMD3<Float>, to targetPoint: Entity) {
        guard var adcComponent = entity.components[ADCComponent.self] else { return }
        
        // Update component with target information
        adcComponent.targetEntityID = targetPoint.id
        adcComponent.startWorldPosition = start
        adcComponent.targetWorldPosition = targetPoint.position(relativeTo: nil)
        
        // Reset movement state
        adcComponent.state = .moving
        adcComponent.movementProgress = 0
        adcComponent.elapsedTime = 0
        adcComponent.needsRetarget = false
        
        // Apply the updated component
        entity.components[ADCComponent.self] = adcComponent
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
    
    private static func look(at target: SIMD3<Float>, from position: SIMD3<Float>) -> simd_quatf {
        let direction = normalize(target - position)
        return simd_quaternion(from: [0, 0, 1], to: direction)
    }
}
