import RealityKit
import Foundation

/// A system that handles ADC movement and targeting behavior
@MainActor
public final class ADCMovementSystem: System {
    // MARK: - Properties
    static let query = EntityQuery(where: .has(ADCComponent.self))
    
    // MARK: - Configuration
    private static let numSteps: Double = 120
    private static let baseArcHeight: Float = 1.2
    private static let arcHeightRange: ClosedRange<Float> = 0.6...1.2
    private static let baseStepDuration: TimeInterval = 0.016
    private static let speedRange: ClosedRange<Float> = 1.2...3.0
    private static let spinSpeedRange: ClosedRange<Float> = 4.0...8.0
    private static let totalDuration: TimeInterval = numSteps * baseStepDuration
    private static let minDistance: Float = 0.5
    private static let maxDistance: Float = 3.0
    private static let proteinSpinSpeed: Float = Float.random(in: 8.0...10.0)
    private static let impactForce: Float = 0.05
    private static let angularImpact: Float = 0.1
    private static let attachmentOffset = SIMD3<Float>(0, -0.08, 0)
    
    // Movement phases
    private static let accelerationPhase: Float = 0.2
    private static let decelerationPhase: Float = 0.2
    private static let minSpeedMultiplier: Float = 0.4
    
    // Animation timing
    private static let scaleUpDuration: TimeInterval = 0.15
    private static let scaleDownDuration: TimeInterval = 0.15
    private static let scaleUpFactor: Float = 1.2
    
    // MARK: - Initialization
    required public init(scene: Scene) {}
    
    // MARK: - Public API
    @MainActor
    public static func startMovement(entity: Entity, from start: SIMD3<Float>, to targetPoint: Entity) {
        guard var adcComponent = entity.components[ADCComponent.self] else {
            print("ERROR: No ADCComponent found on entity")
            return
        }
        
        // Set up movement
        adcComponent.state = .moving
        adcComponent.movementProgress = 0
        adcComponent.targetEntityID = targetPoint.id
        adcComponent.startWorldPosition = start
        
        // Set target cell ID if available
        if let cancerCell = ADCMovementSystem.findParentCancerCell(for: targetPoint, in: entity.scene!) {
            if let cellComponent = cancerCell.components[CancerCellComponent.self] {
                adcComponent.targetCellID = cellComponent.cellID
            }
        }
        
        // Calculate distance-based speed adjustment
        let distance = length(targetPoint.position(relativeTo: nil) - start)
        let normalizedDistance = (distance - minDistance) / (maxDistance - minDistance)
        let clampedDistance = max(0, min(1, normalizedDistance))
        
        // For close distances, increase the minimum speed
        let adjustedSpeedRange = clampedDistance < 0.3 
            ? ClosedRange(uncheckedBounds: (lower: 1.5, upper: 2.0))
            : speedRange
        
        adcComponent.speed = Float.random(in: adjustedSpeedRange)
        
        // Update the component
        entity.components[ADCComponent.self] = adcComponent
        
        // Set initial position
        entity.position = start
        
        // Stop any existing sounds and start drone
        entity.stopAllAudio()
        if let audioComponent = entity.components[AudioLibraryComponent.self],
           let droneSound = audioComponent.resources["Drones_01.wav"] {
            entity.playAudio(droneSound)
        }
    }
    
    // MARK: - System Update
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
                print("⚠️ Target entity not found - attempting retarget")
                if Self.findAndSetNewTarget(entity: entity, 
                                     component: &adcComponent, 
                                     currentPosition: entity.position(relativeTo: nil),
                                     scene: context.scene) {
                    entity.components[ADCComponent.self] = adcComponent
                } else {
                    print("⚠️ No valid targets found - resetting ADC")
                    Self.resetADC(entity: entity, component: &adcComponent)
                }
                continue
            }
            
            // Validate target and handle retargeting if needed
            if !Self.validateTarget(targetEntity, adcComponent, in: context.scene) {
                print("⚠️ Target no longer valid - attempting retarget")
                if Self.findAndSetNewTarget(entity: entity, 
                                     component: &adcComponent, 
                                     currentPosition: entity.position(relativeTo: nil),
                                     scene: context.scene) {
                    entity.components[ADCComponent.self] = adcComponent
                } else {
                    print("⚠️ No valid targets found - resetting ADC")
                    Self.resetADC(entity: entity, component: &adcComponent)
                }
                continue
            }
            
            let target = targetEntity.position(relativeTo: nil)
            
            // Update movement progress
            adcComponent.movementProgress += Float(context.deltaTime) / Float(Self.totalDuration)
            
            if adcComponent.movementProgress >= 1.0 {
                Self.handleImpact(entity: entity, 
                           component: &adcComponent, 
                           target: targetEntity,
                           context: context)
            } else {
                Self.updateMovement(entity: entity,
                             start: start,
                             target: target,
                             progress: adcComponent.movementProgress,
                             deltaTime: context.deltaTime)
            }
            
            entity.components[ADCComponent.self] = adcComponent
        }
    }
    
    private static func validateTarget(_ target: Entity, _ component: ADCComponent, in scene: Scene) -> Bool {
        // Check if target attachment point is still valid
        guard let attachComponent = target.components[AttachmentPoint.self],
              attachComponent.cellID == component.targetCellID else {
            print("⚠️ Attachment point no longer valid")
            return false
        }
        
        // Find parent cancer cell to check hit count
        var current = target
        while let parent = current.parent {
            if let cellComponent = parent.components[CancerCellComponent.self],
               cellComponent.hitCount < cellComponent.requiredHits {
                return true
            }
            current = parent
        }
        
        print("⚠️ Cancer cell no longer valid")
        return false
    }
    
    private static func findAndSetNewTarget(entity: Entity, 
                                   component: inout ADCComponent, 
                                   currentPosition: SIMD3<Float>,
                                   scene: Scene) -> Bool {
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
        
        // Set new target if found
        if let (newTarget, newCellID) = bestTarget {
            print("🎯 Retargeting ADC to new cancer cell (ID: \(newCellID))")
            
            // Mark the chosen point as occupied
            if let attachComponent = newTarget.components[AttachmentPoint.self] {
                var updatedAttach = attachComponent
                updatedAttach.isOccupied = true
                newTarget.components[AttachmentPoint.self] = updatedAttach
            }
            
            component.targetEntityID = newTarget.id
            component.targetCellID = newCellID
            component.startWorldPosition = currentPosition
            component.movementProgress = 0
            component.speed = Float.random(in: Self.speedRange)
            return true
        }
        
        return false
    }
    
    private static func resetADC(entity: Entity, component: inout ADCComponent) {
        component.state = .idle
        component.targetEntityID = nil
        component.targetCellID = nil
        component.movementProgress = 0
        entity.stopAllAudio()
        entity.components[ADCComponent.self] = component
    }
    
    private static func handleImpact(entity: Entity, 
                            component: inout ADCComponent,
                            target: Entity,
                            context: SceneUpdateContext) {
        // Stop movement audio
        entity.stopAllAudio()
        
        // Play impact sound
        if let audioComponent = entity.components[AudioLibraryComponent.self],
           let impactSound = audioComponent.resources["Impact_01.wav"] {
            entity.playAudio(impactSound)
        }
        
        // Update cancer cell hit count
        if let cellID = component.targetCellID {
            Self.updateCancerCellHitCount(cellID: cellID, context: context)
        }
        
        // Attach ADC to target point
        entity.position = target.position(relativeTo: nil) + Self.attachmentOffset
        component.state = .attached
    }
    
    private static func updateMovement(entity: Entity,
                              start: SIMD3<Float>,
                              target: SIMD3<Float>,
                              progress: Float,
                              deltaTime: TimeInterval) {
        // Calculate Bezier curve position
        let distance = length(target - start)
        let midPoint = Self.mix(start, target, t: 0.5)
        let heightOffset = distance * 0.5 * Self.baseArcHeight
        let controlPoint = midPoint + SIMD3<Float>(0, heightOffset, 0)
        
        let t1 = 1.0 - progress
        let position = t1 * t1 * start + 2 * t1 * progress * controlPoint + progress * progress * target
        
        // Update position
        entity.position = position
        
        // Set initial orientation
        if progress <= 0.01 {
            let direction = normalize(target - start)
            let baseOrientation = simd_quatf(from: [0, 0, 1], to: direction)
            entity.orientation = baseOrientation
        }
        
        // Update protein spin
        if let proteinComplex = entity.findEntity(named: "antibodyProtein_complex") {
            let spinRotation = simd_quatf(angle: Float(deltaTime) * Self.proteinSpinSpeed,
                                        axis: [-1, 0, 0])
            proteinComplex.orientation = proteinComplex.orientation * spinRotation
        }
        
        // Calculate and update orientation
        let tangentStep1 = (controlPoint - start) * (1 - progress)
        let tangentStep2 = (target - controlPoint) * progress
        let tangent = normalize(2 * (tangentStep1 + tangentStep2))
        entity.orientation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: tangent)
    }
    
    // MARK: - State Handlers
    private func handleIdleState(entity: Entity, component: inout ADCComponent, context: SceneUpdateContext) {
        // If we have no target, try to find one
        if component.targetEntityID == nil {
            if let target = findNearestValidTarget(for: entity, in: context) {
                component.targetEntityID = target.id
                component.startWorldPosition = entity.position(relativeTo: nil)
                
                // Set target cell ID if available
                if let cancerCell = ADCMovementSystem.findParentCancerCell(for: target, in: context.scene),
                   let cellComponent = cancerCell.components[CancerCellComponent.self] {
                    component.targetCellID = cellComponent.cellID
                }
                
                component.state = .moving
                component.movementProgress = 0
                
                // Start movement from current position
                ADCMovementSystem.startMovement(entity: entity, from: entity.position(relativeTo: nil), to: target)
            }
        }
    }
    
    private func handleRetargetingState(entity: Entity, component: inout ADCComponent, context: SceneUpdateContext) {
        // Stop any existing sounds
        entity.stopAllAudio()
        
        // Clear existing target
        component.targetEntityID = nil
        component.targetCellID = nil
        
        // Try to find a new target
        if let newTarget = findNearestValidTarget(for: entity, in: context) {
            component.targetEntityID = newTarget.id
            component.startWorldPosition = entity.position(relativeTo: nil)
            
            // Set new target cell ID
            if let cancerCell = ADCMovementSystem.findParentCancerCell(for: newTarget, in: context.scene),
                   let cellComponent = cancerCell.components[CancerCellComponent.self] {
                component.targetCellID = cellComponent.cellID
            }
            
            component.state = .moving
            component.movementProgress = 0
            
            // Start new movement
            ADCMovementSystem.startMovement(entity: entity, from: entity.position(relativeTo: nil), to: newTarget)
        } else {
            // No valid target found, go to idle
            component.state = .idle
        }
        
        entity.components[ADCComponent.self] = component
    }
    
    private func handleMovingState(entity: Entity, component: inout ADCComponent, context: SceneUpdateContext) {
        guard let start = component.startWorldPosition,
              let targetID = component.targetEntityID,
              let target = context.scene.findEntity(id: targetID) else {
            // Target no longer exists, enter retargeting state
            component.state = .retargeting
            entity.components[ADCComponent.self] = component
            return
        }
        
        // Validate target is still valid
        if let cancerCell = Self.findParentCancerCell(for: target, in: context.scene),
           let cellComponent = cancerCell.components[CancerCellComponent.self] {
            if cellComponent.cellID != component.targetCellID {
                // Target cell changed, enter retargeting state
                component.state = .retargeting
                entity.components[ADCComponent.self] = component
                return
            }
        } else {
            // Cancer cell no longer exists, enter retargeting state
            component.state = .retargeting
            entity.components[ADCComponent.self] = component
            return
        }
        
        // Update progress with phase-based speed multiplier
        let speedMultiplier = calculateSpeedMultiplier(progress: component.movementProgress)
        component.movementProgress += Float(context.deltaTime) * component.speed * speedMultiplier
        
        if component.movementProgress >= 1.0 {
            handleArrival(entity: entity, component: &component, target: target, context: context)
            return
        }
        
        // Calculate current position and update entity
        updateEntityPosition(entity: entity, 
                           progress: component.movementProgress,
                           start: start,
                           target: target.position(relativeTo: nil),
                           deltaTime: context.deltaTime)
        
        entity.components[ADCComponent.self] = component
    }
    
    private func calculateSpeedMultiplier(progress: Float) -> Float {
        if progress < Self.accelerationPhase {
            let t = progress / Self.accelerationPhase
            return Self.mix(Self.minSpeedMultiplier, 1.0, t: Self.smoothstep(0, 1, t))
        } else if progress > (1.0 - Self.decelerationPhase) {
            let t = (progress - (1.0 - Self.decelerationPhase)) / Self.decelerationPhase
            return Self.mix(1.0, Self.minSpeedMultiplier, t: Self.smoothstep(0, 1, t))
        }
        return 1.0
    }
    
    private func updateEntityPosition(entity: Entity, progress: Float, start: SIMD3<Float>, target: SIMD3<Float>, deltaTime: TimeInterval) {
        // Calculate bezier path position
        let distance = length(target - start)
        let midPoint = Self.mix(start, target, t: 0.5)
        let heightOffset = distance * 0.5 * Float.random(in: Self.arcHeightRange)
        let controlPoint = midPoint + SIMD3<Float>(0, heightOffset, 0)
        
        let t1 = 1.0 - progress
        let position = t1 * t1 * start + 2 * t1 * progress * controlPoint + progress * progress * target
        
        // Update position
        entity.position = position
        
        // Update protein spin
        if let proteinComplex = entity.findEntity(named: "antibodyProtein_complex") {
            let spinRotation = simd_quatf(angle: Float(deltaTime) * Self.proteinSpinSpeed, axis: [-1, 0, 0])
            proteinComplex.orientation = proteinComplex.orientation * spinRotation
        }
        
        // Update orientation to face movement direction
        let direction = simd_normalize(target - position)
        entity.orientation = simd_quatf(from: [0, 0, 1], to: direction)
    }
    
    private func handleArrival(entity: Entity, component: inout ADCComponent, target: Entity, context: SceneUpdateContext) {
        // Apply impact physics to cancer cell
        if let cancerCell = ADCMovementSystem.findParentCancerCell(for: target, in: context.scene),
           var cellPhysics = cancerCell.components[PhysicsMotionComponent.self] {
            // Calculate impact direction and force
            let impactDirection = normalize(target.position(relativeTo: nil) - entity.position(relativeTo: nil))
            cellPhysics.linearVelocity += impactDirection * Self.impactForce
            
            // Add random angular velocity
            let randomSign: Float = Bool.random() ? 1.0 : -1.0
            cellPhysics.angularVelocity += SIMD3<Float>(0, randomSign * Self.angularImpact, 0)
            
            cancerCell.components[PhysicsMotionComponent.self] = cellPhysics
        }
        
        // Stop movement sounds
        entity.stopAllAudio()
        
        // Attach to target
        entity.removeFromParent()
        target.addChild(entity)
        entity.orientation = target.orientation(relativeTo: nil)
        entity.position = Self.attachmentOffset
        
        // Scale animation
        let scaleUpTransform = Transform(scale: SIMD3<Float>(repeating: Self.scaleUpFactor))
        entity.move(to: scaleUpTransform, relativeTo: entity.parent, duration: Self.scaleUpDuration, timingFunction: .easeInOut)
        
        Task {
            try? await Task.sleep(for: .milliseconds(Int(Self.scaleUpDuration * 1000)))
            let originalTransform = Transform(scale: SIMD3<Float>(repeating: 1.0))
            entity.move(to: originalTransform, relativeTo: entity.parent, duration: Self.scaleDownDuration, timingFunction: .easeInOut)
        }
        
        // Play attach sound
        if let audioComponent = entity.components[AudioLibraryComponent.self],
           let attachSound = audioComponent.resources["ADC_Attach.wav"] {
            entity.playAudio(attachSound)
        }
        
        // Update state
        component.state = .attached
        entity.components[ADCComponent.self] = component
        
        // Update cancer cell hit count
        if let cellID = component.targetCellID {
            Self.updateCancerCellHitCount(cellID: cellID, context: context)
        }
    }
    
    private func handleAttachedState(entity: Entity, component: inout ADCComponent, context: SceneUpdateContext) {
        guard let targetID = component.targetEntityID,
              let targetEntity = context.scene.findEntity(id: targetID) else {
            // Target is gone, go back to retargeting
            component.state = .retargeting
            entity.components[ADCComponent.self] = component
            return
        }
        
        // Maintain attachment
        entity.position = Self.attachmentOffset
        entity.orientation = targetEntity.orientation(relativeTo: nil)
    }
    
    // MARK: - Target Validation and Retargeting
    private static func findParentCancerCell(for entity: Entity, in scene: Scene) -> Entity? {
        var current = entity
        while let parent = current.parent {
            if parent.components[CancerCellComponent.self] != nil {
                return parent
            }
            current = parent
        }
        return nil
    }
    
    private func findNearestValidTarget(for entity: Entity, in context: SceneUpdateContext) -> Entity? {
        let cancerCellQuery = EntityQuery(where: .has(CancerCellComponent.self))
        let potentialTargets = context.scene.performQuery(cancerCellQuery)
        
        return potentialTargets
            .filter { target in
                validateTarget(target, for: entity)
            }
            .min(by: { a, b in
                let distA = length(a.position(relativeTo: nil) - entity.position(relativeTo: nil))
                let distB = length(b.position(relativeTo: nil) - entity.position(relativeTo: nil))
                return distA < distB
            })
    }
    
    private func validateTarget(_ target: Entity, for entity: Entity) -> Bool {
        // Must have cancer cell component
        guard target.components[CancerCellComponent.self] != nil else { 
            return false 
        }
        
        // Check distance
        let distance = length(target.position(relativeTo: nil) - entity.position(relativeTo: nil))
        return distance >= Self.minDistance && distance <= Self.maxDistance
    }
    
    private static func updateCancerCellHitCount(cellID: Int, context: SceneUpdateContext) {
        let cellQuery = EntityQuery(where: .has(CancerCellComponent.self))
        for cellEntity in context.scene.performQuery(cellQuery) {
            guard let cellComponent = cellEntity.components[CancerCellComponent.self],
                  cellComponent.cellID == cellID else { continue }
            
            var updatedComponent = cellComponent
            updatedComponent.hitCount += 1
            cellEntity.components[CancerCellComponent.self] = updatedComponent
            
            NotificationCenter.default.post(
                name: Notification.Name("UpdateCancerCell"),
                object: nil,
                userInfo: ["entity": cellEntity]
            )
            break
        }
    }
    
    // MARK: - Math Helpers
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
}
