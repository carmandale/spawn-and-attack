//
//  CurvedPathView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 11/19/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Combine

struct CurvedPathView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.realityKitScene) var scene
    
    @State private var rootEntity: Entity?
    @State private var adcEntity: Entity?
    
    // Store event subscriptions
    @State private var adcHitSubscription: EventSubscription?
    @State private var adcPathCompletedSubscription: EventSubscription?
    
    var body: some View {
        RealityView { content, attachments in
            // Create root entity
            let root = Entity()
            content.add(root)
            rootEntity = root
            
            // Load and spawn cancer cells
            Task {
                do {
                    // Load the template
                    let cancerCellTemplate = try await Entity(named: "CancerCell-spawn", in: realityKitContentBundle)
                    print("\n=== Loading Cancer Cells ===")
                    
                    // Create first cell (clone of template)
                    let cell1 = cancerCellTemplate.clone(recursive: true)
                    cell1.name = "cancer_cell_1"
                    cell1.position = [-0.5, 1.5, -1.5]
                    print("\n=== Cancer Cell 1 Component Hierarchy ===")
                    inspectEntityHierarchy(cell1, level: 0)
                    
                    // Add meter to first cell
                    if let leftMeter = attachments.entity(for: "leftMeter") {
                        leftMeter.position = [0, 1.0, 0]
                        cell1.addChild(leftMeter)
                    }
                    
                    root.addChild(cell1)
                    print("\nCell 1 loaded at position:", cell1.position)
                    print("Cell 1 components:", cell1.components.map { type(of: $0) })
                    
                    // Create second cell (clone of template)
                    let cell2 = cancerCellTemplate.clone(recursive: true)
                    cell2.name = "cancer_cell_2"
                    cell2.position = [0.5, 1.5, -1.5]
                    print("\n=== Cancer Cell 2 Component Hierarchy ===")
                    inspectEntityHierarchy(cell2, level: 0)
                    
                    // Add meter to second cell
                    if let rightMeter = attachments.entity(for: "rightMeter") {
                        rightMeter.position = [0, 2.0, 0]
                        cell2.addChild(rightMeter)
                    }
                    
                    root.addChild(cell2)
                    print("\nCell 2 loaded at position:", cell2.position)
                    print("Cell 2 components:", cell2.components.map { type(of: $0) })
                    
                    print("\nScene hierarchy:")
                    inspectEntityHierarchy(root, level: 0)
                } catch {
                    print("Error loading cancer cells:", error)
                }
            }
            
            // Load the ADC entity
            if let adc = try? await Entity(named: "ADC-spawn", in: realityKitContentBundle) {
                print("\n=== Initial ADC Template Load ===")
                inspectEntityHierarchy(adc, level: 0)
                
                // Store the inner Root entity that has the audio components as our template
                if let innerRoot = adc.children.first {
                    adcEntity = innerRoot
                    print("ADC entity loaded (using inner Root with audio)")
                    print("Entity name:", innerRoot.name)
                    print("Components:", innerRoot.components.map { type(of: $0) })
                }
            }
        } update: { content, attachments in
            // Update hit counts from components
            if let immersiveContent = content.entities.first?.children.first {
                for cell in findCancerCells(in: immersiveContent) {
                    if let component = cell.components[CancerCellComponent.self] {
//                        hitTracker.updateHitCount(for: cell, count: component.hitCount)
                    }
                }
            }
        } attachments: {
            // Create progress views for all cancer cells
            ForEach(findCancerCells(in: rootEntity?.children.first?.children.first), id: \.id) { cell in
                Attachment(id: String(cell.id)) {
                   CircleProgressView(hits: .init(
                       get: { hitTracker.getHitCount(for: cell) },
                       set: { _ in /* Read-only binding */ }
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
    
    private func findCancerCells(in entity: Entity?) -> [Entity] {
        guard let entity = entity else { return [] }
        var cells: [Entity] = []
        
        func recursiveSearch(_ entity: Entity) {
            if entity.name.contains("cancerCell") {
                cells.append(entity)
            }
            for child in entity.children {
                recursiveSearch(child)
            }
        }
        
        recursiveSearch(entity)
        return cells
    }
    
    private func handleTap(on entity: Entity) {
        print("Tapped entity: \(entity.name)")
        
        guard let scene = scene else {
            print("No scene available")
            return
        }
        
        // Get the tapped position in world space
        let worldPosition = entity.position(relativeTo: nil)
        
        // Find nearest available attachment point
        guard let attachPoint = AttachmentSystem.getAvailablePoint(in: scene, nearPosition: worldPosition) else {
            print("No available attach point found")
            return
        }
        print("Found attach point: \(attachPoint.name)")
        
        let attachWorldPosition = attachPoint.convert(position: .zero, to: nil)
        print("Attachment point world position: \(attachWorldPosition)")
        
        // Generate random point for spawn position
        let spawnPoint = SIMD3<Float>(
            Float.random(in: -0.25...0.25),
            Float.random(in: 0.25...1.1),
            Float.random(in: -1.0...(-0.25))
        )
        print("Spawn point: \(spawnPoint)")
        
        // Use the attachment point's world position as the target
        spawnAndAnimateCubeWithCurvedPath(
            from: spawnPoint,
            to: attachWorldPosition,
            targetEntity: attachPoint
        )
    }
    
    private func spawnAndAnimateCubeWithCurvedPath(from start: SIMD3<Float>, to end: SIMD3<Float>, targetEntity: Entity) {
        guard let root = rootEntity, let adcTemplate = adcEntity else { return }
        
        // Clone the preloaded entity to avoid reusing the same instance
        let adc = adcTemplate.clone(recursive: true)
        
        // Initial setup
        adc.position = start
        root.addChild(adc)
        
        // Calculate path points
        let numSteps = 60
        let arcHeight: Float = 0.3
        let slalomWidth: Float = 0.2
        let stepDuration: TimeInterval = 0.03
        let totalDuration = TimeInterval(numSteps) * stepDuration
        var positions: [SIMD3<Float>] = []
        
        // Generate curved path points
        for i in 0...numSteps {
            let p = Float(i) / Float(numSteps)
            let basePoint = mix(start, end, t: p)
            let heightProgress = 1.0 - pow(p * 2.0 - 1.0, 2)
            let height = arcHeight * heightProgress
            let sideOffset = sin(p * .pi * 1.5) * slalomWidth * (1.0 - p)
            let position = basePoint + SIMD3<Float>(sideOffset, height, 0)
            positions.append(i == numSteps ? end : position)
        }
        
        // Animation complete handler
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            // Stop drone sound and play attach sound
            adc.stopAllAudio()
            adc.position = .zero
            targetEntity.addChild(adc)
            
            // Play attach sound
            playAttachSound(for: targetEntity)
            
            // Mark the attachment point as occupied
            AttachmentSystem.markPointAsOccupied(targetEntity)
            
            // Update cancer cell state
            if let cellEntity = self.findCancerCell(from: targetEntity) {
                self.handleCellHit(cellEntity, adc: adc)
            }
        }
        
        for i in 0..<positions.count {
            let startDelay = Double(i) * stepDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                var transform = adc.transform
                transform.translation = positions[i]
                adc.move(to: transform, relativeTo: nil, duration: stepDuration, timingFunction: .linear)
            }
        }
    }
    
    private func findCancerCell(from entity: Entity) -> Entity? {
        var current: Entity? = entity
        while let parent = current?.parent {
            if parent.name.contains("cancerCell") {
                return parent
            }
            current = parent
        }
        return nil
    }
    
    private func inspectEntityHierarchy(_ entity: Entity, level: Int) {
        let indent = String(repeating: "  ", count: level)
        print("\(indent)Entity: \(entity.name)")
        print("\(indent)Components: \(entity.components.map { type(of: $0) })")
        
        for child in entity.children {
            inspectEntityHierarchy(child, level: level + 1)
        }
    }
    
    private func setupAndPlayDroneSound(for entity: Entity) {
        print("\n=== Setting Up Drone Sound ===")
        print("Entity name:", entity.name)
        print("Available components:", entity.components.map { type(of: $0) })
        
        guard let audioLibraryComponent = entity.components[AudioLibraryComponent.self] else {
            print("ERROR: No AudioLibraryComponent found")
            return
        }
        print("Audio Library Found:")
        print("- Available resources:", audioLibraryComponent.resources.keys)
        
        guard let audioResource = audioLibraryComponent.resources["Drones_01.wav"] else {
            print("ERROR: Drones_01.wav not found in resources")
            return
        }
        print("Found drone audio resource, playing...")
        
        entity.playAudio(audioResource)
    }
    
    private func playAttachSound(for entity: Entity) {
        print("\n=== Playing Attach Sound ===")
        print("Entity name:", entity.name)
        guard let parentADC = entity.children.first else {
            print("No child ADC found on entity")
            return
        }
        
        guard let audioLibraryComponent = parentADC.components[AudioLibraryComponent.self],
              let audioResource = audioLibraryComponent.resources["Sonic_Pulse_Hit_01.wav"]
        else { return }
        
        parentADC.playAudio(audioResource)
    }
    
    private func handleADCHit(_ event: GameEvents.ADCHit) {
        handleCellHit(event.cell, adc: event.adc)
    }
    
    private func handleCellHit(_ cell: Entity, adc: Entity) {
        if var component = cell.components[CancerCellComponent.self] {
            component.hitCount += 1
            cell.components[CancerCellComponent.self] = component
            
            // Update hit tracker and game state
//            hitTracker.updateHitCount(for: cell, count: component.hitCount)
//            appModel.totalHits += 1
//            appModel.incrementScore()
//            
//            // Check if cell should be destroyed
//            if component.hitCount >= 3 { // TODO: Make this configurable
//                destroyCancerCell(cell)
//                appModel.cellsDestroyed += 1
//                appModel.incrementScore(by: 5) // Bonus points for destroying
            }
        }
    }
    
    private func destroyCancerCell(_ cell: Entity) {
        // Fade out animation
        if var modelComponent = cell.components[ModelComponent.self] {
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: .white.withAlphaComponent(0))
            modelComponent.materials = [material]
            cell.components[ModelComponent.self] = modelComponent
        }
        
        // Remove after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            cell.removeFromParent()
        }
    }


//#Preview(immersionStyle: .mixed) {
//    CurvedPathView()
//        .environment(AppModel())
//}
