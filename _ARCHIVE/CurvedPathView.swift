// //
// //  CurvedPathView.swift
// //  SpawnAndAttrack
// //
// //  Created by Dale Carman on 11/19/24.
// //

// import SwiftUI
// import RealityKit
// import RealityKitContent
// import Combine

// struct CurvedPathView: View {
//    @Environment(AppModel.self) private var appModel
//    @Environment(\.realityKitScene) var scene
   
//    @State private var rootEntity: Entity?
//    @State private var adcEntity: Entity?
//    @State private var cell1: Entity?
//    @State private var cell2: Entity?
   
//    // Store event subscriptions
//    @State private var adcHitSubscription: EventSubscription?
//    @State private var adcPathCompletedSubscription: EventSubscription?
   
//    var body: some View {
//        RealityView { content, attachments in
//            // Create root entity
//            let root = Entity()
//            content.add(root)
//            rootEntity = root
           
//            // Load and spawn cancer cells
//            Task {
//                do {
//                    // Load the template
//                    let cancerCellTemplate = try await Entity(named: "CancerCell-spawn", in: realityKitContentBundle)
//                    print("\n=== Loading Cancer Cells ===")
//                    print("Template hierarchy:")
//                    inspectEntityHierarchy(cancerCellTemplate, level: 0)
                   
//                    // Create first cell (clone of template)
//                    if let newCell1 = cancerCellTemplate.clone(recursive: true) {
//                        newCell1.name = "cancer_cell_1"
//                        newCell1.position = [-0.5, 1.5, -1.5]
                       
//                        // Add CancerCellComponent
//                        newCell1.components[CancerCellComponent.self] = CancerCellComponent()
                       
//                        // Add meter to first cell
//                        if let meter = attachments.entity(for: "cell1") {
//                            meter.position = [0, 0.5, 0]
//                            newCell1.addChild(meter)
//                        }
                       
//                        root.addChild(newCell1)
//                        cell1 = newCell1
//                        print("\nCell 1 loaded at position:", newCell1.position)
//                        print("Cell 1 name:", newCell1.name)
//                        print("Cell 1 components:", newCell1.components.map { type(of: $0) })
//                        print("\nCell 1 hierarchy:")
//                        inspectEntityHierarchy(newCell1, level: 0)
//                    }
                   
//                    // Create second cell (clone of template)
//                    if let newCell2 = cancerCellTemplate.clone(recursive: true) {
//                        newCell2.name = "cancer_cell_2"
//                        newCell2.position = [0.5, 1.5, -1.5]
                       
//                        // Add CancerCellComponent
//                        newCell2.components[CancerCellComponent.self] = CancerCellComponent()
                       
//                        // Add meter to second cell
//                        if let meter = attachments.entity(for: "cell2") {
//                            meter.position = [0, 0.5, 0]
//                            newCell2.addChild(meter)
//                        }
                       
//                        root.addChild(newCell2)
//                        cell2 = newCell2
//                        print("\nCell 2 loaded at position:", newCell2.position)
//                        print("Cell 2 name:", newCell2.name)
//                        print("Cell 2 components:", newCell2.components.map { type(of: $0) })
//                    }
                   
//                    print("\nTracked cancer cells:", [cell1, cell2].compactMap { $0?.name })
//                } catch {
//                    print("Error loading cancer cells:", error)
//                }
//            }
           
//            // Load the ADC entity
//            if let adc = try? await Entity(named: "ADC-spawn", in: realityKitContentBundle) {
//                print("\n=== Initial ADC Template Load ===")
//                // inspectEntityHierarchy(adc, level: 0)
               
//                // Store the inner Root entity that has the audio components as our template
//                if let innerRoot = adc.children.first {
//                    adcEntity = innerRoot
//                    print("ADC entity loaded (using inner Root with audio)")
//                    print("Entity name:", innerRoot.name)
//                    print("Components:", innerRoot.components.map { type(of: $0) })
//                }
//            }
//        } update: { content, attachments in
//            // Updates handled by root entity
//        } attachments: {
//            Attachment(id: "cell1") {
//                CircleProgressView(hits: .init(
//                    get: { 
//                        guard let cell = cell1,
//                              let system = appModel.cancerCellSystem else { return 0 }
//                        return system.getHitCount(for: cell)
//                    },
//                    set: { _ in /* Read-only binding */ }
//                ))
//            }
//            Attachment(id: "cell2") {
//                CircleProgressView(hits: .init(
//                    get: { 
//                        guard let cell = cell2,
//                              let system = appModel.cancerCellSystem else { return 0 }
//                        return system.getHitCount(for: cell)
//                    },
//                    set: { _ in /* Read-only binding */ }
//                ))
//            }
//        }
//        .gesture(
//            SpatialTapGesture()
//                .targetedToAnyEntity()
//                .onEnded { value in
//                    handleTap(on: value.entity)
//                }
//        )
//    }
   
//    private func findParentCancerCell(from attachmentPoint: Entity) -> Entity? {
//        // Walk up the hierarchy until we find a cancer cell
//        var current: Entity? = attachmentPoint
//        while let parent = current?.parent {
//            if [cell1, cell2].contains(parent) {
//                return parent
//            }
//            current = parent
//        }
//        return nil
//    }
   
//    private func handleTap(on entity: Entity) {
//        print("Tapped entity: \(entity.name)")
       
//        guard let scene = scene else {
//            print("No scene available")
//            return
//        }
       
//        // Get the tapped position in world space
//        let worldPosition = entity.position(relativeTo: nil)
       
//        // Find nearest available attachment point
//        guard let attachPoint = AttachmentSystem.getAvailablePoint(in: scene, nearPosition: worldPosition) else {
//            print("No available attach point found")
//            return
//        }
//        print("Found attach point: \(attachPoint.name)")
       
//        let attachWorldPosition = attachPoint.convert(position: .zero, to: nil)
//        print("Attachment point world position: \(attachWorldPosition)")
       
//        // Generate random point for spawn position
//        let spawnPoint = SIMD3<Float>(
//            Float.random(in: -0.25...0.25),
//            Float.random(in: 0.25...1.1),
//            Float.random(in: -1.0...(-0.25))
//        )
//        print("Spawn point: \(spawnPoint)")
       
//        // Use the attachment point's world position as the target
//        spawnAndAnimateCubeWithCurvedPath(
//            from: spawnPoint,
//            to: attachWorldPosition,
//            targetEntity: attachPoint
//        )
//    }
   
//    private func spawnAndAnimateCubeWithCurvedPath(from start: SIMD3<Float>, to end: SIMD3<Float>, targetEntity: Entity) {
//        guard let root = rootEntity, let adcTemplate = adcEntity else { return }
       
//        // Clone the preloaded entity to avoid reusing the same instance
//        let adc = adcTemplate.clone(recursive: true)
       
//        // Initial setup
//        adc.position = start
//        root.addChild(adc)
       
//        // Calculate path points
//        let numSteps = 60
//        let arcHeight: Float = 0.3
//        let slalomWidth: Float = 0.2
//        let stepDuration: TimeInterval = 0.03
//        let totalDuration = TimeInterval(numSteps) * stepDuration
//        var positions: [SIMD3<Float>] = []
       
//        // Generate curved path points
//        for i in 0...numSteps {
//            let p = Float(i) / Float(numSteps)
//            let basePoint = mix(start, end, t: p)
//            let heightProgress = 1.0 - pow(p * 2.0 - 1.0, 2)
//            let height = arcHeight * heightProgress
//            let sideOffset = sin(p * .pi * 1.5) * slalomWidth * (1.0 - p)
//            let position = basePoint + SIMD3<Float>(sideOffset, height, 0)
//            positions.append(i == numSteps ? end : position)
//        }
       
//        // Animation complete handler
//        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
//            // Stop drone sound and play attach sound
//            adc.stopAllAudio()
//            adc.position = .zero
//            targetEntity.addChild(adc)
           
//            // Play attach sound
//            playAttachSound(for: targetEntity)
           
//            // Mark the attachment point as occupied
//            AttachmentSystem.markPointAsOccupied(targetEntity)
           
//            // Update cancer cell state
//            if let cellEntity = self.findParentCancerCell(from: targetEntity) {
//                self.handleCellHit(cellEntity, adc: adc)
//            }
//        }
       
//        for i in 0..<positions.count {
//            let startDelay = Double(i) * stepDuration
//            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
//                var transform = adc.transform
//                transform.translation = positions[i]
//                adc.move(to: transform, relativeTo: nil, duration: stepDuration, timingFunction: .linear)
//            }
//        }
//    }
   
//    private func inspectEntityHierarchy(_ entity: Entity, level: Int) {
//        let indent = String(repeating: "  ", count: level)
//        print("\(indent)Entity: \(entity.name)")
//        print("\(indent)Components: \(entity.components.map { type(of: $0) })")
       
//        for child in entity.children {
//            inspectEntityHierarchy(child, level: level + 1)
//        }
//    }
   
//    private func setupAndPlayDroneSound(for entity: Entity) {
//        print("\n=== Setting Up Drone Sound ===")
//        print("Entity name:", entity.name)
//        print("Available components:", entity.components.map { type(of: $0) })
       
//        guard let audioLibraryComponent = entity.components[AudioLibraryComponent.self] else {
//            print("ERROR: No AudioLibraryComponent found")
//            return
//        }
//        print("Audio Library Found:")
//        print("- Available resources:", audioLibraryComponent.resources.keys)
       
//        guard let audioResource = audioLibraryComponent.resources["Drones_01.wav"] else {
//            print("ERROR: Drones_01.wav not found in resources")
//            return
//        }
//        print("Found drone audio resource, playing...")
       
//        entity.playAudio(audioResource)
//    }
   
//    private func playAttachSound(for entity: Entity) {
//        print("\n=== Playing Attach Sound ===")
//        print("Entity name:", entity.name)
//        guard let parentADC = entity.children.first else {
//            print("No child ADC found on entity")
//            return
//        }
       
//        guard let audioLibraryComponent = parentADC.components[AudioLibraryComponent.self],
//              let audioResource = audioLibraryComponent.resources["Sonic_Pulse_Hit_01.wav"]
//        else { return }
       
//        parentADC.playAudio(audioResource)
//    }
   
//    private func handleADCHit(_ event: GameEvents.ADCHit) {
//        print("\n=== ADC Hit Event Received ===")
//        print("Cell entity: \(event.cell.name)")
//        print("ADC entity: \(event.adc.name)")
//        handleCellHit(event.cell, adc: event.adc)
//    }
   
//    private func handleCellHit(_ cell: Entity, adc: Entity) {
//        print("\n=== Handling Cell Hit ===")
//        print("Processing hit on:", cell.name)
       
//        appModel.cancerCellSystem?.registerHit(on: cell)
//    }
   
//    private func destroyCancerCell(_ cell: Entity) {
//        // Fade out animation
//        if var modelComponent = cell.components[ModelComponent.self] {
//            var material = PhysicallyBasedMaterial()
//            material.baseColor = .init(tint: .white.withAlphaComponent(0))
//            modelComponent.materials = [material]
//            cell.components[ModelComponent.self] = modelComponent
//        }
       
//        // Remove after delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            cell.removeFromParent()
//        }
//    }
// }

// //#Preview(immersionStyle: .mixed) {
// //    CurvedPathView()
// //        .environment(AppModel())
// //}
