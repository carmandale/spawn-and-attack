import SwiftUI
import RealityKit
import RealityKitContent

struct AttackCancerView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.realityKitScene) private var scene
    @Environment(HandTrackingViewModel.self) private var handTracking
    
    // Store entities
    @State private var rootEntity: Entity?
    @State private var adcTemplate: Entity?
    
    // Debug counters
    @State private var totalTaps: Int = 0
    @State private var successfulADCLaunches: Int = 0
    
    // Store subscription to prevent deallocation
    @State private var subscription: EventSubscription?
    
    // MARK: - Setup Functions
    private func setupRoot() -> Entity {
        let root = Entity()
        rootEntity = root
        return root
    }

    private func setupEnvironment(in root: Entity) async {
        // IBL
        do {
            try await IBLUtility.addImageBasedLighting(to: root, imageName: "metro_noord_2k")
        } catch {
            print("Failed to setup IBL: \(error)")
        }
        
        // Environment
        if let attackCancerScene = await appModel.assetLoadingManager.instantiateEntity("attack_cancer_environment") {
            root.addChild(attackCancerScene)
            setupCollisions(in: attackCancerScene)
        }
    }

    private func setupCollisions(in scene: Entity) {
        if let scene = scene.scene {
            let query = EntityQuery(where: .has(BloodVesselWallComponent.self))
            let objectsToModify = scene.performQuery(query)
            
            for object in objectsToModify {
                if var collision = object.components[CollisionComponent.self] {
                    collision.filter.group = .cancerCell
                    collision.filter.mask = .adc
                    object.components[CollisionComponent.self] = collision
                }
            }
        }
    }

    @State var handTrackedEntity: Entity = {
        let handAnchor = AnchorEntity(.hand(.left, location: .aboveHand))
        return handAnchor
    }()

    var body: some View {
        RealityView { content, attachments in
            print("\n=== RealityView Make Closure Start ===")
            let root = setupRoot()
            content.add(root)
            
            // Setup hand tracking using the shared view model
            content.add(handTracking.setupContentEntity())
            
            content.add(handTrackedEntity)
            if let attachmentEntity = attachments.entity(for: "HopeMeter") {
                attachmentEntity.components[BillboardComponent.self] = .init()
                handTrackedEntity.addChild(attachmentEntity)
            }
            
            Task {
                // Environment setup
                await setupEnvironment(in: root)
                
                // ADC Template
                if let adcEntity = await appModel.assetLoadingManager.instantiateEntity("adc") {
                    adcTemplate = adcEntity
                }
                
                
                
                // Cancer Cells
                if let cancerCellTemplate = await appModel.assetLoadingManager.instantiateEntity("cancer_cell") {
                    spawnCancerCells(in: root, from: cancerCellTemplate, count: appModel.gameState.maxCancerCells)
                    
                    // Setup UI attachments after cells are spawned
                    for i in 0..<appModel.gameState.maxCancerCells {
                        if let meter = attachments.entity(for: "\(i)"),
                           root.findEntity(named: "cancer_cell_\(i)") != nil {
                            root.addChild(meter)
                            
                            // Add UIAttachmentComponent to the UI entity (meter)
                            let uiAttachment = UIAttachmentComponent(attachmentID: i)
                            meter.components[UIAttachmentComponent.self] = uiAttachment
                            
                            // Add BillboardComponent to make the hit counter face the camera
                            meter.components.set(BillboardComponent())
                        }
                    }
                }
            }
            
            subscription = content.subscribe(to: CollisionEvents.Began.self) { [weak appModel] event in
                appModel?.gameState.handleCollisionBegan(event)
            }
        } attachments: {
            // Existing cancer cell counter attachments
            ForEach(0..<appModel.gameState.maxCancerCells, id: \.self) { i in
                Attachment(id: "\(i)") {
                    HitCounterView(
                        hits: Binding(
                            get: {
                                appModel.gameState.cancerCells
                                    .first(where: { cell in
                                        cell.components[CancerCellComponent.self]?.cellID == i
                                    })?
                                    .components[CancerCellComponent.self]?
                                    .hitCount ?? 0
                            },
                            set: { _ in }
                        ),
                        requiredHits: appModel.gameState.cancerCells
                            .first(where: { cell in
                                cell.components[CancerCellComponent.self]?.cellID == i
                            })?
                            .components[CancerCellComponent.self]?
                            .requiredHits ?? 18,
                        isDestroyed: Binding(
                            get: {
                                appModel.gameState.cancerCells
                                    .first(where: { cell in
                                        cell.components[CancerCellComponent.self]?.cellID == i
                                    })?
                                    .components[CancerCellComponent.self]?
                                    .isDestroyed ?? false
                            },
                            set: { _ in }
                        )
                    )
                }
            }
            Attachment(id: "HopeMeter") {
                HopeMeterView()
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    let location3D = value.convert(value.location3D, from: .local, to: .scene)
                    totalTaps += 1
                    print("\n👆 TAP #\(totalTaps) on \(value.entity.name)")
                    
                    Task {
                        await handleTap(on: value.entity, location: location3D)
                    }
                }
        )
        .onAppear {
            // Start the game when view appears
            appModel.gameState.startGame()
        }
    }
    
    // MARK: - Private Methods 
    private func handleTap(on entity: Entity, location: SIMD3<Float>) async {
        print("Tapped entity: \(entity.name)")
        
        // Get pinch distances for both hands to determine which hand tapped
        let leftPinchDistance = handTracking.getPinchDistance(.left) ?? Float.infinity
        let rightPinchDistance = handTracking.getPinchDistance(.right) ?? Float.infinity
        
        // Determine which hand's position to use
        let handPosition: SIMD3<Float>?
        if leftPinchDistance < rightPinchDistance {
            handPosition = handTracking.getFingerPosition(.left)
            print("Left hand tap detected")
        } else{
            handPosition = handTracking.getFingerPosition(.right)
            print("Right hand tap detected")
        }
        
        // Proceed with existing cancer cell logic
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
        
        // Use the detected hand position if available, otherwise fall back to tap location
        let spawnPosition = handPosition ?? location
        await spawnADC(from: spawnPosition, targetPoint: attachPoint, forCellID: cellID)
    }
    
    private func spawnADC(from position: SIMD3<Float>, targetPoint: Entity, forCellID cellID: Int) async {
        guard let template = adcTemplate,
              let root = rootEntity else {
            print("❌ ADC #\(successfulADCLaunches + 1) Failed - Missing template or root")
            return
        }
        
        successfulADCLaunches += 1
        print("✅ ADC #\(successfulADCLaunches) Launched (Total Taps: \(totalTaps))")
        
        // Set the flag for first ADC fired
        if !appModel.gameState.hasFirstADCBeenFired {
            appModel.gameState.hasFirstADCBeenFired = true
        }
        
        // Increment ADC count
        appModel.gameState.incrementADCsDeployed()
        
        // Clone the template
        let adc = template.clone(recursive: true)
        
        // Update ADCComponent properties
        guard var adcComponent = adc.components[ADCComponent.self] else { return }
        adcComponent.targetCellID = cellID
        adcComponent.startWorldPosition = position  // Use the hand position
        adc.components[ADCComponent.self] = adcComponent
        
        // Set initial position
        adc.position = position
        
        // Add to scene
        root.addChild(adc)
        
        // Start movement
        ADCMovementSystem.startMovement(entity: adc, from: position, to: targetPoint)
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
        let radius = Float.random(in: 1.5...3.5)  // Orbit radius range
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
            // Generate random required hits between 7 and 18 for new cells
            cancerCell.requiredHits = Int.random(in: 7...18)
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
                        // print("Set cellID \(cellID) for attachment point \(entity.name)")
                        break
                    }
                    current = parent.parent
                }
            }
        }
    }
}
