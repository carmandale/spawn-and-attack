////
////  CurvedPathView.swift
////  SpawnAndAttrack
////
////  Created by Dale Carman on 11/19/24.
////
//
//import SwiftUI
//import RealityKit
//import RealityKitContent
//
//struct CurvedPathViewOLD: View {
//    @Environment(AppModel.self) private var appModel
//    @Environment(\.realityKitScene) var scene
//    let rknt = "RealityKit.NotificationTrigger"
//    
//    @State private var rootEntity: Entity?
//    @State private var adcEntity: Entity?
//    @State private var leftCellHits: Int = 0
//    @State private var rightCellHits: Int = 0
//    
//    // Track available attachment points
//    @State private var leftCellAttachPoints: [Entity] = []
//    @State private var rightCellAttachPoints: [Entity] = []
//    @State private var usedAttachPoints: Set<Entity> = []
//    @State private var attachmentCellMap: [Entity: Bool] = [:] // true for left, false for right
//    
//    var body: some View {
//        RealityView { content, attachments in
//            // Create root entity
//            let root = Entity()
//            content.add(root)
//            rootEntity = root
//            
//            // Load the immersive content if available
//            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
//                root.addChild(immersiveContentEntity)
//                
//                // Find and setup left cancer cell
//                if let leftCell = immersiveContentEntity.findEntity(named: "cancerCell_left") {
//                    if let leftMeter = attachments.entity(for: "leftMeter") {
//                        leftMeter.position = [0, 0.5, 0]
//                        leftCell.addChild(leftMeter)
//                    }
//                    
//                    // Find all attachment points for left cell
//                    findAttachmentPoints(in: leftCell) { points in
//                        leftCellAttachPoints = points
//                        points.forEach { attachmentCellMap[$0] = true }
//                    }
//                }
//                
//                // Find and setup right cancer cell
//                if let rightCell = immersiveContentEntity.findEntity(named: "cancerCell_right") {
//                    if let rightMeter = attachments.entity(for: "rightMeter") {
//                        rightMeter.position = [0, 0.5, 0]
//                        rightCell.addChild(rightMeter)
//                    }
//                    
//                    // Find all attachment points for right cell
//                    findAttachmentPoints(in: rightCell) { points in
//                        rightCellAttachPoints = points
//                        points.forEach { attachmentCellMap[$0] = false }
//                    }
//                }
//            }
//            
//            // Load the ADC entity
//            if let adc = try? await Entity(named: "ADC-spawn", in: realityKitContentBundle) {
//                print("\n=== Initial ADC Template Load ===")
//                
//                // Find the inner Root with audio resources
//                if let innerRoot = adc.children.first,
//                   let audioLib = innerRoot.components[AudioLibraryComponent.self] {
//                    
//                    print("Found audio library with resources:", audioLib.resources.keys)
//                    
//                    // Create our own AudioLibraryComponent with those resources
//                    var newAudioLib = AudioLibraryComponent()
//                    
//                    // Transfer the resources
//                    for (name, resource) in audioLib.resources {
//                        newAudioLib.resources[name] = resource
//                    }
//                    
//                    // Add to our main entity
//                    adc.components[AudioLibraryComponent.self] = newAudioLib
//                    
//                    // Also transfer the spatial audio component if it exists
//                    if let spatialAudio = innerRoot.components[SpatialAudioComponent.self] {
//                        adc.components[SpatialAudioComponent.self] = spatialAudio
//                    }
//                    
//                    print("Transferred audio resources to top-level entity")
//                }
//                
//                print("ADC entity loaded")
//                print("Entity name:", adc.name)
//                print("Entity children:", adc.children.map { $0.name })
//                print("Components:", adc.components.map { type(of: $0) })
//                print("\nRecursive entity inspection:")
//                inspectEntityHierarchy(adc, level: 0)
//                adcEntity = adc
//            }
//        } update: { content, attachments in
//            // Updates handled by root entity
//        } attachments: {
//            Attachment(id: "leftMeter") {
//                CircleProgressView(hits: $leftCellHits)
//            }
//            Attachment(id: "rightMeter") {
//                CircleProgressView(hits: $rightCellHits)
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
//    
//    private func findAttachmentPoints(in entity: Entity, completion: @escaping ([Entity]) -> Void) {
//        var points: [Entity] = []
//        
//        func recursiveSearch(_ entity: Entity) {
//            if entity.components[AttachmentPoint.self] != nil {
//                points.append(entity)
//            }
//            for child in entity.children {
//                recursiveSearch(child)
//            }
//        }
//        
//        recursiveSearch(entity)
//        completion(points)
//    }
//    
//    private func getAvailableAttachPoint(isLeft: Bool) -> Entity? {
//        print("\nLooking for attachment point (isLeft: \(isLeft))")
//        guard let scene = scene else {
//            print("No scene available")
//            return nil
//        }
//        print("Scene found")
//        
////        let point = AttachmentSystem.getAvailablePoint(in: scene, isLeft: isLeft)
////        if let point = point {
////            print("Found available point: \(point.name)")
////            AttachmentSystem.markPointAsOccupied(point)
////            print("Marked point as occupied")
////        } else {
////            print("No available points found")
////        }
////        return point
//        return nil
//    }
//    
//    private func handleTap(on entity: Entity) {
//        print("Tapped entity: \(entity.name)")
//        
//        let isLeftCell = entity.name.contains("left")
//        print("Is left cell: \(isLeftCell)")
//        
//        guard let attachPoint = getAvailableAttachPoint(isLeft: isLeftCell) else {
//            print("No available attach point found")
//            return
//        }
//        print("Found attach point: \(attachPoint.name)")
//        
//        let worldPosition = attachPoint.convert(position: .zero, to: nil)
//        print("World position: \(worldPosition)")
//        
//        // Generate random point for spawn position
//        let spawnPoint = SIMD3<Float>(
//            Float.random(in: -0.25...0.25),
//            Float.random(in: 0.25...1.1),
//            Float.random(in: -1.0...(-0.25))
//        )
//        print("Spawn point: \(spawnPoint)")
//        
//        // Use the attachment point's world position as the target
//        spawnAndAnimateCubeWithCurvedPath(
//            from: spawnPoint,
//            to: worldPosition,
//            targetEntity: attachPoint
//        )
//    }
//    
//    private func spawnAndAnimateCubeWithCurvedPath(from start: SIMD3<Float>, to end: SIMD3<Float>, targetEntity: Entity) {
//        guard let root = rootEntity, let adcTemplate = adcEntity else { return }
//        
//        // Clone the preloaded entity to avoid reusing the same instance
//        let adc = adcTemplate.clone(recursive: true)
//        print("\n=== Cloned ADC Entity ===")
//        print("Components after clone:", adc.components.map { type(of: $0) })
//        if let audioLib = adc.components[AudioLibraryComponent.self] {
//            print("Audio Library Found in Clone:")
//            print("- Available resources:", audioLib.resources.keys)
//            print("- Drone sound exists:", audioLib.resources["Drones_01.wav"] != nil)
//            print("- Attach sound exists:", audioLib.resources["Sonic_Pulse_Hit_01.wav"] != nil)
//        } else {
//            print("WARNING: No AudioLibraryComponent found in cloned ADC")
//        }
//        root.addChild(adc)
//        
//        // Set initial position and start drone sound
//        adc.position = start
//        setupAndPlayDroneSound(for: adc)
//        
//        // Calculate the path parameters
//        let distance = length(end - start)
//        let arcHeight = distance * 0.375 / 2.0
//        let slalomWidth = distance * 0.2 / 2.0
//        
//        let numSteps = 120
//        let totalDuration: TimeInterval = 1.0
//        let stepDuration = totalDuration / Double(numSteps)
//        
//        var positions: [SIMD3<Float>] = []
//        for i in 0...numSteps {
//            let p = Float(i) / Float(numSteps)
//            let basePoint = mix(start, end, t: p)
//            let heightProgress = 1.0 - pow(p * 2.0 - 1.0, 2)
//            let height = arcHeight * heightProgress
//            let sideOffset = sin(p * .pi * 1.5) * slalomWidth * (1.0 - p)
//            let position = basePoint + SIMD3<Float>(sideOffset, height, 0)
//            positions.append(i == numSteps ? end : position)
//        }
//        
//        // Increment hit counter when animation completes
//        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
//            let isLeft = self.attachmentCellMap[targetEntity] ?? false
//            if isLeft {
//                self.leftCellHits = min(self.leftCellHits + 1, 18)
//                if self.leftCellHits == 18 {
//                    self.triggerCancerDeath(isLeft: true)
//                }
//            } else {
//                self.rightCellHits = min(self.rightCellHits + 1, 18)
//                if self.rightCellHits == 18 {
//                    self.triggerCancerDeath(isLeft: false)
//                }
//            }
//            
//            // Stop drone sound and play attach sound
//            adc.stopAllAudio()
//            adc.position = .zero
//            targetEntity.addChild(adc)
//            self.playAttachSound(for: targetEntity)
//            
//            // Mark the attachment point as occupied
//            AttachmentSystem.markPointAsOccupied(targetEntity)
//        }
//        
//        for i in 0..<positions.count {
//            let startDelay = Double(i) * stepDuration
//            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
//                var transform = adc.transform
//                transform.translation = positions[i]
//                adc.move(to: transform, relativeTo: nil, duration: stepDuration, timingFunction: .linear)
//            }
//        }
//    }
//    
//    private func setupAndPlayDroneSound(for entity: Entity) {
//        print("\n=== Setting Up Drone Sound ===")
//        print("Entity name:", entity.name)
//        print("Available components:", entity.components.map { type(of: $0) })
//        
//        guard let audioLibraryComponent = entity.components[AudioLibraryComponent.self] else {
//            print("ERROR: No AudioLibraryComponent found")
//            return
//        }
//        print("Audio Library Found:")
//        print("- Available resources:", audioLibraryComponent.resources.keys)
//        
//        guard let audioResource = audioLibraryComponent.resources["Drones_01.wav"] else {
//            print("ERROR: Drones_01.wav not found in resources")
//            return
//        }
//        print("Found drone audio resource, playing...")
//        
//        entity.playAudio(audioResource)
//    }
//    
//    private func playAttachSound(for entity: Entity) {
//        print("\n=== Playing Attach Sound ===")
//        print("Entity name:", entity.name)
//        guard let parentADC = entity.children.first else {
//            print("No child ADC found on entity")
//            return
//        }
//        
//        guard let audioLibraryComponent = parentADC.components[AudioLibraryComponent.self],
//              let audioResource = audioLibraryComponent.resources["Sonic_Pulse_Hit_01.wav"]
//        else { return }
//        
//        parentADC.playAudio(audioResource)
//    }
//    
//    private func triggerCancerDeath(isLeft: Bool) {
//        guard let scene = scene else { return }
//        let identifier = isLeft ? "cancerDeathLeft" : "cancerDeathRight"
//        let notification = Notification(name: .init(rknt),
//                                    userInfo: ["\(rknt).Scene" : scene,
//                                          "\(rknt).Identifier" : identifier])
//        NotificationCenter.default.post(notification)
//    }
//    
//    private func inspectEntityHierarchy(_ entity: Entity, level: Int) {
//        let indent = String(repeating: "  ", count: level)
//        print("\(indent)Entity: \(entity.name)")
//        print("\(indent)Components: \(entity.components.map { type(of: $0) })")
//        
//        // Special handling for ModelComponent
//        if let modelComponent = entity.components[ModelComponent.self] {
//            print("\(indent)Model Component Materials:", modelComponent.materials.count)
//            for (index, material) in modelComponent.materials.enumerated() {
//                print("\(indent)  Material \(index): \(type(of: material))")
//            }
//        }
//        
//        // Special handling for AudioLibraryComponent
//        if let audioLib = entity.components[AudioLibraryComponent.self] {
//            print("\(indent)Audio Library Resources:", audioLib.resources.keys)
//        }
//        
//        print("\(indent)Children count: \(entity.children.count)")
//        for child in entity.children {
//            inspectEntityHierarchy(child, level: level + 1)
//        }
//    }
//}
//
////#Preview(immersionStyle: .mixed) {
////    CurvedPathView()
////        .environment(AppModel())
////}
