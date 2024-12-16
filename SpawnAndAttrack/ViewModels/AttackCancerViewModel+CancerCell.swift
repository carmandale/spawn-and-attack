import SwiftUI
import RealityKit
import RealityKitContent

extension AttackCancerViewModel {
    func spawnCancerCells(in root: Entity, from template: Entity, count: Int) {
        // Create force entity with central gravity
        let forceEntity = createForceEntity()
        root.addChild(forceEntity)
        
        for i in 0..<count {
            spawnSingleCancerCell(in: root, from: template, index: i)
        }
    }
    
    private func createForceEntity() -> Entity {
        let forceEntity = Entity()
        // REF: Planet is positioned at [0, 0.5, -2] relative to device in reference project
        forceEntity.position = [0, 1.5, 0]  // Center point where we want gravity
        
        // REF: gravityMagnitude = 0.1 in reference Gravity.swift
        let gravityMagnitude: Float = 0.1
        // REF: minimumDistance = 0.2 in reference Gravity.swift
        let gravity = Gravity(gravityMagnitude: gravityMagnitude, minimumDistance: 0.2)
        // REF: mask = .all.subtracting(.actualEarthGravity) in reference Entity+Planet.swift
        let forceEffect = ForceEffect(
            effect: gravity,
            mask: .all.subtracting(.actualEarthGravity)  // Exactly like reference project
        )
        forceEntity.components.set(ForceEffectComponent(effects: [forceEffect]))
        return forceEntity
    }
    
    private func spawnSingleCancerCell(in root: Entity, from template: Entity, index: Int) {
        let cell = template.clone(recursive: true)
        cell.name = "cancer_cell_\(index)"
        
        if let complexCell = cell.findEntity(named: "cancerCell_complex") {
            configureCellPosition(complexCell)
            configureCellPhysics(complexCell)
            configureCellMovement(complexCell)
            setupCellIdentification(complexCell, cellID: index)
            
            root.addChild(cell)
            appModel.gameState.registerCancerCell(cell)
            
            setupAttachmentPoints(for: cell, complexCell: complexCell, cellID: index)
        } else {
            print("Warning: Could not find cancerCell_complex entity")
        }
    }
    
    private func configureCellPosition(_ cell: Entity) {
        // Generate random orbit parameters
        // REF: Asteroids use radius 1...3 in reference ImmersiveViewModel+AstronomicalObjects.swift
        let radius: Float = .random(in: 1...2)  // Slightly smaller range for cancer cells
        let theta = Float.random(in: 0...(2 * .pi))  // Random angle around the circle
        
        // Calculate position
        let x = radius * cos(theta)
        let z = radius * sin(theta)
        let y = Float.random(in: 1...2)  // Random height
        
        cell.position = [x, y, z]
    }
    
    private func configureCellPhysics(_ cell: Entity) {
        // Add collision component for ADC interactions
        let shape = ShapeResource.generateSphere(radius: 0.1)
        let collisionComponent = CollisionComponent(
            shapes: [shape],
            filter: .init(group: .cancerCell, mask: .adc)
        )
        cell.components.set(collisionComponent)
        
        var physicsBody = PhysicsBodyComponent(mode: .dynamic)
        physicsBody.isAffectedByGravity = false
        physicsBody.linearDamping = 0  // Higher damping to prevent too much movement
        physicsBody.massProperties.mass = 1.0
        cell.components[PhysicsBodyComponent.self] = physicsBody
        
        // Add PhysicsMotionComponent for impulse application
        cell.components.set(PhysicsMotionComponent())
        
        // REF: Planet uses radius = 0.12 or 0.25 in reference project
        let shape2 = ShapeResource.generateSphere(radius: 0.32)  // Cancer cell size
        let collisionComponent2 = CollisionComponent(
            shapes: [shape2],
            filter: .init(group: .cancerCell, mask: .all)
        )
        cell.components.set(collisionComponent2)
        
        // REF: Planet uses mass = 1.0 in reference project
        var physicsBody2 = PhysicsBodyComponent(shapes: [shape2], mass: 1.0, mode: .dynamic)
        // REF: isAffectedByGravity = false in reference project (uses custom gravity)
        physicsBody2.isAffectedByGravity = false
        // REF: linearDamping = 0 in reference project
        physicsBody2.linearDamping = 0
        // REF: angularDamping = 0 in reference project
        physicsBody2.angularDamping = 0
        cell.components[PhysicsBodyComponent.self] = physicsBody2
    }
    
    private func configureCellMovement(_ cell: Entity) {
        // Calculate orbital parameters
        let radius = sqrt(cell.position.x * cell.position.x + cell.position.z * cell.position.z)
        let theta = atan2(cell.position.x, cell.position.z)
        
        // Calculate orbital velocity exactly like reference
        // REF: orbitSpeed = sqrt(gravityMagnitude / radius) in reference Entity+Planet.swift calculateVelocity()
        let gravityMagnitude: Float = 0.1
        let orbitSpeed = sqrt(gravityMagnitude / radius) * 1.0  // Added scaling factor to slow down
        
        // REF: Direction calculation matches reference Entity+Planet.swift calculateVelocity()
        let orbitDirection = SIMD3<Float>(
            cos(theta),   // X component
            0,           // No vertical velocity
            -sin(theta)  // Z component
        )
        
        // REF: Angular velocity = [0, 1, 0] * 0.3 in reference Entity+Planet.swift
        let motionComponent = PhysicsMotionComponent(
            linearVelocity: orbitDirection * orbitSpeed,
            angularVelocity: [Float.random(in: -0...1), Float.random(in: -1...1), Float.random(in: -0...1)] * 1.0  // Add random tumbling
        )
        cell.components.set(motionComponent)
    }
    
    private func setupCellIdentification(_ cell: Entity, cellID: Int) {
        if var cancerCell = cell.components[CancerCellComponent.self] {
            cancerCell.cellID = cellID
            // Generate random required hits between 7 and 18 for new cells
            cancerCell.requiredHits = Int.random(in: 7...18)
            cell.components[CancerCellComponent.self] = cancerCell
        }
    }
    
    private func setupAttachmentPoints(for cell: Entity, complexCell: Entity, cellID: Int) {
        if let scene = cell.scene {
            let attachPointQuery = EntityQuery(where: .has(AttachmentPoint.self))
            let objectsToModify = scene.performQuery(attachPointQuery)
            
            for object in objectsToModify {
                // Check if this attachment point is part of our cell's hierarchy
                var current = object.parent
                while let parent = current {
                    if parent == complexCell {
                        var attachPoint = object.components[AttachmentPoint.self]!
                        attachPoint.cellID = cellID
                        object.components[AttachmentPoint.self] = attachPoint
                        break
                    }
                    current = parent.parent
                }
            }
        }
    }
} 