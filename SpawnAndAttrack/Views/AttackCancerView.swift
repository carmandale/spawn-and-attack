import SwiftUI
import RealityKit
import RealityKitContent

struct AttackCancerView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.realityKitScene) private var scene
    @Environment(\.openWindow) private var openWindow
    private let cellCount = AppModel.maxCancerCells
    
    // Store entities
    @State private var rootEntity: Entity?
    @State private var adcTemplate: Entity?
    
    // Store subscription to prevent deallocation - needed for collision detection
    @State private var subscription: EventSubscription?
    
    var body: some View {
        ZStack {
            RealityView { content, attachments in
                print("\n=== RealityView Make Closure Start ===")
                let root = Entity()
                content.add(root)
                rootEntity = root
                
                // Load Attack Cancer Environment from pre-loaded assets
                if let attackCancerScene = await appModel.assetLoadingManager.instantiateEntity("attack_cancer_environment") {
                    print("\n=== Loading Attack Cancer Environment ===")
                    appModel.assetLoadingManager.inspectEntityHierarchy(attackCancerScene)
                    root.addChild(attackCancerScene)
                } else {
                    print("Failed to load AttackCancerEnvironment from asset manager")
                }
                
                Task {
                    // Retrieve ADC template from asset manager
                    if let adcEntity = await appModel.assetLoadingManager.instantiateEntity("adc") {
                        print("\n=== Loading ADC Template ===")
                        appModel.assetLoadingManager.inspectEntityHierarchy(adcEntity)
                        adcTemplate = adcEntity
                    } else {
                        print("Failed to retrieve ADC template from asset manager")
                    }
                    
                    // Retrieve Cancer Cell template from asset manager
                    guard let cancerCellTemplate = await appModel.assetLoadingManager.instantiateEntity("cancer_cell") else {
                        print("Failed to retrieve Cancer Cell template from asset manager")
                        return
                    }
                    print("\n=== Cancer Cell Template ===")
                    appModel.assetLoadingManager.inspectEntityHierarchy(cancerCellTemplate)
                    
                    // Spawn cancer cells
                    spawnCancerCells(in: root, from: cancerCellTemplate, count: cellCount)
                    
                    // Add UI attachments to each cancer cell
                    for i in 0..<cellCount {
                        if let meter = attachments.entity(for: "\(i)"),
                           let root = rootEntity,
                           root.findEntity(named: "cancer_cell_\(i)") != nil {
                            root.addChild(meter)
                            
                            // Add UIAttachmentComponent to the UI entity (meter)
                            let uiAttachment = UIAttachmentComponent(attachmentID: i)
                            meter.components[UIAttachmentComponent.self] = uiAttachment
                            
                            // Add BillboardComponent to make the hit counter face the camera
                            meter.components.set(RealityKitContent.BillboardComponent())
                        }
                    }
                }
                
                // Subscribe to collision events
                subscription = content.subscribe(to: CollisionEvents.Began.self) { [weak appModel] event in
                    appModel?.handleCollisionBegan(event)
                }
            } attachments: {
                ForEach(0..<cellCount, id: \.self) { i in
                    Attachment(id: "\(i)") {
                        HitCounterView(
                            hits: Binding(
                                get: {
                                    appModel.cancerCells
                                        .first(where: { cell in
                                            cell.components[CancerCellComponent.self]?.cellID == i
                                        })?
                                        .components[CancerCellComponent.self]?
                                        .hitCount ?? 0
                                },
                                set: { _ in }
                            ),
                            requiredHits: CancerCellComponent.requiredHits
                        )
                    }
                }
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    Task {
                        await handleTap(on: value.entity)
                    }
                }
        )
        
        // Show CompletedView when game phase is completed
        if appModel.gamePhase == .completed {
            CompletedView()
        }
    }
    
    // Mark: Private Methods 
    private func handleTap(on entity: Entity) async {
        print("Tapped entity: \(entity.name)")
        
        guard let scene = scene,
              let cellComponent = entity.components[CancerCellComponent.self],
              let cellID = cellComponent.cellID else {
            print("No scene available or no cell component/ID")
            return
        }
        print("Found cancer cell with ID: \(cellID)")
        
        guard let attachPoint = AttachmentSystem.getAvailablePoint(in: scene, forCellID: cellID) else {
            print("No available attach point found")
            return
        }
        print("Found attach point: \(attachPoint.name)")
        
        AttachmentSystem.markPointAsOccupied(attachPoint)
        await spawnADC(targetPoint: attachPoint, forCellID: cellID)
    }
    
    private func spawnADC(targetPoint: Entity, forCellID cellID: Int) async {
        guard let template = adcTemplate,
              let root = rootEntity else {
            print("No ADC template, root entity, or scene available")
            return
        }
        
        // Clone the template
        let adc = template.clone(recursive: true)
        
        // Update ADCComponent properties
        guard var adcComponent = adc.components[ADCComponent.self] else { return }
        adcComponent.targetCellID = cellID
        adc.components[ADCComponent.self] = adcComponent
        
        // Generate random spawn position
        let spawnPoint = SIMD3<Float>(
            Float.random(in: -0.125...0.125),
            Float.random(in: 0.25...1.1),
            Float.random(in: -0.5...(-0.125))
        )
        
        // Set initial position
        adc.position = spawnPoint
        
        // Add to root first
        root.addChild(adc)
        
        // Start movement using static method
        ADCMovementSystem.startMovement(entity: adc, from: spawnPoint, to: targetPoint)
        
        // let shape = ShapeResource.generateSphere(radius: 0.076)  // ADC size
        // let collisionComponent = CollisionComponent(
        //     shapes: [shape],
        //     filter: .init(group: .adc, mask: .cancerCell)
        // )
        // adc.components.set(collisionComponent)
        
        // var physicsBody = PhysicsBodyComponent(mode: .dynamic)
        // physicsBody.isAffectedByGravity = false
        // physicsBody.linearDamping = 0.2
        // physicsBody.massProperties.mass = 0.4
        // adc.components[PhysicsBodyComponent.self] = physicsBody
        
        // After spawning ADC
        appModel.incrementADCsDeployed()
    }
    
    private func spawnCancerCells(in root: Entity, from template: Entity, count: Int) {
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
        var component = CancerCellComponent(cellID: index)
        print("\n=== Cancer Cell Spawn ===")
        print("Spawning cell \(index) with requiredHits: \(component.requiredHits)")
        cell.components[CancerCellComponent.self] = component
        // After setting component
        if let verifyComponent = cell.components[CancerCellComponent.self] {
            print("Verified cell \(index) has requiredHits: \(verifyComponent.requiredHits)")
        }
        cell.name = "cancer_cell_\(index)"
        
        if let complexCell = cell.findEntity(named: "cancerCell_complex") {
            configureCellPosition(complexCell)
            configureCellPhysics(complexCell)
            configureCellMovement(complexCell)
            setupCellIdentification(complexCell, cellID: index)
            
            root.addChild(cell)
            appModel.registerCancerCell(cell)
            
            setupAttachmentPoints(for: cell, complexCell: complexCell, cellID: index)
        } else {
            print("Warning: Could not find cancerCell_complex entity")
        }
    }
    
    private func configureCellPosition(_ cell: Entity) {
        // Generate random orbit parameters
        // REF: Asteroids use radius 1...3 in reference ImmersiveViewModel+AstronomicalObjects.swift
        let radius = Float.random(in: 2.0...4.0)  // Orbit radius range
        let theta = Float.random(in: 0...(2 * .pi))  // Random angle
        
        // Place cell on orbit
        cell.position = [
            sin(theta) * radius,  // X position on circle
            Float.random(in: 0.5...2.5),  // Y can vary somewhat
            cos(theta) * radius   // Z position on circle
        ]
    }
    
    private func configureCellPhysics(_ cell: Entity) {
        // Add physics components for ADC impact
        let shape = ShapeResource.generateSphere(radius: 0.32)  // Match cell size
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
        // Update movement for slower tumbling motion
//        if var movement = cell.components[MovementComponent.self] {
//            // REF: Planet uses speed = 0.1 in reference Entity+Planet.swift
//            movement.speed = Double.random(in: 0.01...0.1)  // Much slower range
//            movement.axis = [
//                Float.random(in: -1...1),  // Random X rotation
//                Float.random(in: -1...1),  // Random Y rotation
//                Float.random(in: -1...1)   // Random Z rotation
//            ]
//            cell.components[MovementComponent.self] = movement
//        }
        
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
            cell.components[CancerCellComponent.self] = cancerCell
        }
    }
    
    private func setupAttachmentPoints(for cell: Entity, complexCell: Entity, cellID: Int) {
        if let scene = cell.scene {
            let attachPointQuery = EntityQuery(where: .has(AttachmentPoint.self))
            for entity in scene.performQuery(attachPointQuery) {
                // Check if this attachment point is part of our cell's hierarchy
                var current = entity.parent
                while let parent = current {
                    if parent == complexCell {
                        var attachPoint = entity.components[AttachmentPoint.self]!
                        attachPoint.cellID = cellID
                        entity.components[AttachmentPoint.self] = attachPoint
                        print("Set cellID \(cellID) for attachment point \(entity.name)")
                        break
                    }
                    current = parent.parent
                }
            }
        }
    }
}
