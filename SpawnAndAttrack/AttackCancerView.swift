import SwiftUI
import RealityKit
import RealityKitContent

struct AttackCancerView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.realityKitScene) private var scene
    private let cellCount = 10
    
    // Store entities
    @State private var rootEntity: Entity?
    @State private var adcTemplate: Entity?
    
    var body: some View {
        RealityView { content, attachments in
            print("\n=== RealityView Make Closure Start ===")
            let root = Entity()
            content.add(root)
            rootEntity = root
            
            // Load the immersive content if available
            if let BloodVesselSpatialAudio = try? await Entity(named: "Audio-blood-vessel-scene", in: realityKitContentBundle) {
                root.addChild(BloodVesselSpatialAudio)
            }
            
            Task {
                // Load ADC template
                if let adc = try? await Entity(named: "ADC-spawn", in: realityKitContentBundle) {
                    print("\n=== Loading ADC Template ===")
                    if let innerRoot = adc.children.first {
                        adcTemplate = innerRoot
                        print("ADC template loaded (using inner Root with audio)")
                    }
                }
                
                let cancerCellTemplate = try await Entity(named: "CancerCell-spawn", in: realityKitContentBundle)
                print("\n=== Cancer Cell Template ===")
                inspectEntityHierarchy(cancerCellTemplate, level: 0)
                
                spawnCancerCells(in: root, from: cancerCellTemplate, count: cellCount)
                
                // Add UI attachments to each cancer cell
                for i in 0..<cellCount {
                    if let meter = attachments.entity(for: "\(i)"),
                       let cellEntity = root.children.first(where: { $0.name == "cancer_cell_\(i)" }) {
                        print("Adding UI attachment for cell \(i)")
                        root.addChild(meter) // Add to root instead of cell
                        
                        // Add UIAttachmentComponent to the UI entity (meter)
                        var uiAttachment = UIAttachmentComponent(attachmentID: i)
                        meter.components[UIAttachmentComponent.self] = uiAttachment
                        print("Added UIAttachmentComponent to meter \(i) with ID: \(uiAttachment.attachmentID)")
                        
                        // Add BillboardComponent to make the hit counter face the camera
                        meter.components.set(RealityKitContent.BillboardComponent())
                        print("Added BillboardComponent to meter \(i)")
                    }
                }
            }
            print("=== RealityView Make Closure End ===\n")
        } attachments: {
            ForEach(0..<cellCount, id: \.self) { i in
                Attachment(id: "\(i)") {
                    HitCounterView(hits: Binding(
                        get: {
                            appModel.cancerCells
                                .first(where: { cell in
                                    cell.components[CancerCellComponent.self]?.cellID == i
                                })?
                                .components[CancerCellComponent.self]?
                                .hitCount ?? 0
                        },
                        set: { _ in }
                    ))
                }
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    handleTap(on: value.entity)
                }
        )
    }
    
    // Mark: Private Methods 
    private func handleTap(on entity: Entity) {
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
        spawnADC(targetPoint: attachPoint, forCellID: cellID)
    }
    
    private func spawnADC(targetPoint: Entity, forCellID cellID: Int) {
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
    }
    
    private func inspectEntityHierarchy(_ entity: Entity, level: Int) {
        let indent = String(repeating: "  ", count: level)
        print("\(indent)Entity: \(entity.name)")
        print("\(indent)Components: \(entity.components.map { type(of: $0) })")
        
        for child in entity.children {
            inspectEntityHierarchy(child, level: level + 1)
        }
    }
    
    private func spawnCancerCells(in root: Entity, from template: Entity, count: Int) {
        // Create central force entity first
        let forceEntity = Entity()
        forceEntity.position = [0, 1.5, 0]  // Center point where we want gravity
        
        // Create gravity effect exactly as they do
        let gravity = ForceEffect(
            effect: Gravity(minimumDistance: 0.2),
            mask: .default  // We can adjust mask if needed
        )
        forceEntity.components.set(ForceEffectComponent(effects: [gravity]))
        
        root.addChild(forceEntity)
        
        for i in 0..<count {
            let cell = template.clone(recursive: true)
            
            // Configure cell
            cell.name = "cancer_cell_\(i)"
            
            // Wider spacing for positions
            cell.position = [
                Float.random(in: -4...4),    // Wider X range
                Float.random(in: 0...5),     // Higher Y range
                Float.random(in: -5...(-1))  // Deeper Z range
            ]
            
            // Find the cancerCell_complex entity that has our components
            if let complexCell = cell.findEntity(named: "cancerCell_complex") {
                // Update movement for slower tumbling motion
                if var movement = complexCell.components[MovementComponent.self] {
                    movement.speed = Double.random(in: 0.01...0.08)  // Much slower range
                    movement.axis = [
                        Float.random(in: -1...1),  // Random X rotation
                        Float.random(in: -1...1),  // Random Y rotation
                        Float.random(in: -1...1)   // Random Z rotation
                    ]
                    complexCell.components[MovementComponent.self] = movement
                }
                
                // Add physics body matching their asteroid setup exactly
                let radius = length(cell.position)  // Distance from center
                let theta = atan2(cell.position.x, cell.position.z)
                
                var physicsBody = PhysicsBodyComponent(
                    massProperties: .init(mass: 1),  // Match their mass
                    material: .generate(friction: 0.0, restitution: 0.5),
                    mode: .dynamic
                )
                physicsBody.isAffectedByGravity = false  // Only affected by our force effect
                physicsBody.linearDamping = 0            // No damping like their asteroids
                physicsBody.angularDamping = 0
                
                // Calculate initial velocity for orbit exactly as they do
                let orbitSpeed = sqrt(0.1 / radius)  // Using same gravityMagnitude
                let orbitDirection: SIMD3<Float> = [cos(theta), 0, -sin(theta)]
                let orbitVelocity = orbitDirection * orbitSpeed
                
                // Add random angular velocity exactly as they do
                let angularDirection: SIMD3<Float> = normalize([.random(in: 0...1), .random(in: 0...1), .random(in: 0...1)])
                
                complexCell.components[PhysicsMotionComponent.self] = .init(
                    linearVelocity: orbitVelocity,
                    angularVelocity: angularDirection * .pi / 3
                )
                complexCell.components[PhysicsBodyComponent.self] = physicsBody
                complexCell.components[CellPhysicsComponent.self] = .init()
                
                // Set the cell ID in the CancerCellComponent
                if var cancerCell = complexCell.components[CancerCellComponent.self] {
                    cancerCell.cellID = i
                    complexCell.components[CancerCellComponent.self] = cancerCell
                    
                    root.addChild(cell)
                    appModel.registerCancerCell(cell)
                    
                    // Now that the cell is in the scene, set up attachment points
                    if let scene = cell.scene {
                        let attachPointQuery = EntityQuery(where: .has(AttachmentPoint.self))
                        for entity in scene.performQuery(attachPointQuery) {
                            // Check if this attachment point is part of our cell's hierarchy
                            var current = entity.parent
                            while let parent = current {
                                if parent == complexCell {
                                    var attachPoint = entity.components[AttachmentPoint.self]!
                                    attachPoint.cellID = i
                                    entity.components[AttachmentPoint.self] = attachPoint
                                    print("Set cellID \(i) for attachment point \(entity.name)")
                                    break
                                }
                                current = parent.parent
                            }
                        }
                    }
                } else {
                    print("Warning: Could not find CancerCellComponent on complexCell")
                }
            }
        }
    }
}
