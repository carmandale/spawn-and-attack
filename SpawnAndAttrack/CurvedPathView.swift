//
//  CurvedPathView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 11/19/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct CurvedPathView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.realityKitScene) var scene
    let rknt = "RealityKit.NotificationTrigger"
    
    @State private var rootEntity: Entity?
    @State private var adcEntity: Entity?
    @State private var leftCellHits: Int = 0
    @State private var rightCellHits: Int = 0
    
    // Track available attachment points
    @State private var leftCellAttachPoints: [Entity] = []
    @State private var rightCellAttachPoints: [Entity] = []
    @State private var usedAttachPoints: Set<Entity> = []
    @State private var attachmentCellMap: [Entity: Bool] = [:] // true for left, false for right
    
    var body: some View {
        RealityView { content, attachments in
            // Create root entity
            let root = Entity()
            content.add(root)
            rootEntity = root
            
            // Load the immersive content if available
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                root.addChild(immersiveContentEntity)
                
                // Find and setup left cancer cell
                if let leftCell = immersiveContentEntity.findEntity(named: "cancerCell_left") {
                    if let leftMeter = attachments.entity(for: "leftMeter") {
                        leftMeter.position = [0, 0.5, 0]
                        leftCell.addChild(leftMeter)
                    }
                    
                    // Find all attachment points for left cell
                    findAttachmentPoints(in: leftCell) { points in
                        leftCellAttachPoints = points
                        points.forEach { attachmentCellMap[$0] = true }
                    }
                }
                
                // Find and setup right cancer cell
                if let rightCell = immersiveContentEntity.findEntity(named: "cancerCell_right") {
                    if let rightMeter = attachments.entity(for: "rightMeter") {
                        rightMeter.position = [0, 0.5, 0]
                        rightCell.addChild(rightMeter)
                    }
                    
                    // Find all attachment points for right cell
                    findAttachmentPoints(in: rightCell) { points in
                        rightCellAttachPoints = points
                        points.forEach { attachmentCellMap[$0] = false }
                    }
                }
            }
            
            // Load the ADC entity
            if let adc = try? await Entity(named: "ADC-spawn", in: realityKitContentBundle) {
                adcEntity = adc
            }
        } update: { content, attachments in
            // Updates handled by root entity
        } attachments: {
            Attachment(id: "leftMeter") {
                CircleProgressView(hits: $leftCellHits)
            }
            Attachment(id: "rightMeter") {
                CircleProgressView(hits: $rightCellHits)
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
    
    private func findAttachmentPoints(in entity: Entity, completion: @escaping ([Entity]) -> Void) {
        var points: [Entity] = []
        
        func recursiveSearch(_ entity: Entity) {
            if entity.name.starts(with: "attach_") {
                points.append(entity)
            }
            for child in entity.children {
                recursiveSearch(child)
            }
        }
        
        recursiveSearch(entity)
        completion(points)
    }
    
    private func getAvailableAttachPoint(isLeft: Bool) -> Entity? {
        let points = isLeft ? leftCellAttachPoints : rightCellAttachPoints
        let availablePoints = points.filter { !usedAttachPoints.contains($0) }
        guard let selectedPoint = availablePoints.randomElement() else { return nil }
        usedAttachPoints.insert(selectedPoint)
        return selectedPoint
    }
    
    private func handleTap(on entity: Entity) {
        let isLeftCell = entity.name.contains("left")
        guard let attachPoint = getAvailableAttachPoint(isLeft: isLeftCell) else { return }
        
        let worldPosition = attachPoint.convert(position: .zero, to: nil)
        
        // Generate random point for spawn position
        let spawnPoint = SIMD3<Float>(
            Float.random(in: -0.25...0.25),
            Float.random(in: 0.25...1.1),
            Float.random(in: -1.0...(-0.25))
        )
        
        // Use the attachment point's world position as the target
        spawnAndAnimateCubeWithCurvedPath(
            from: spawnPoint,
            to: worldPosition,
            targetEntity: attachPoint
        )
    }
    
    private func spawnAndAnimateCubeWithCurvedPath(from start: SIMD3<Float>, to end: SIMD3<Float>, targetEntity: Entity) {
        guard let root = rootEntity, let adcTemplate = adcEntity else { return }
        
        // Clone the preloaded entity to avoid reusing the same instance
        let adc = adcTemplate.clone(recursive: true)
        root.addChild(adc)
        
        // Set initial position and start drone sound
        adc.position = start
        setupAndPlayDroneSound(for: adc)
        
        // Calculate the path parameters
        let distance = length(end - start)
        let arcHeight = distance * 0.375 / 2.0
        let slalomWidth = distance * 0.2 / 2.0
        
        let numSteps = 120
        let totalDuration: TimeInterval = 1.0
        let stepDuration = totalDuration / Double(numSteps)
        
        var positions: [SIMD3<Float>] = []
        for i in 0...numSteps {
            let p = Float(i) / Float(numSteps)
            let basePoint = mix(start, end, t: p)
            let heightProgress = 1.0 - pow(p * 2.0 - 1.0, 2)
            let height = arcHeight * heightProgress
            let sideOffset = sin(p * .pi * 1.5) * slalomWidth * (1.0 - p)
            let position = basePoint + SIMD3<Float>(sideOffset, height, 0)
            positions.append(i == numSteps ? end : position)
        }
        
        // Increment hit counter when animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            let isLeft = self.attachmentCellMap[targetEntity] ?? false
            if isLeft {
                self.leftCellHits = min(self.leftCellHits + 1, 18)
                if self.leftCellHits == 18 {
                    self.triggerCancerDeath(isLeft: true)
                }
            } else {
                self.rightCellHits = min(self.rightCellHits + 1, 18)
                if self.rightCellHits == 18 {
                    self.triggerCancerDeath(isLeft: false)
                }
            }
            
            // Stop drone sound and play attach sound
            adc.stopAllAudio()
            adc.position = .zero
            targetEntity.addChild(adc)
            self.playAttachSound(for: targetEntity)
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
    
    private func setupAndPlayDroneSound(for entity: Entity) {
        // Configure looping for drone sound
        let configuration = AudioFileResource.Configuration(shouldLoop: true)
        
        // Load the audio source and set its configuration
        guard let audio = try? AudioFileResource.load(
            named: "Drones_01",
            configuration: configuration
        ) else { return }
        
        // Add spatial audio component with forward directivity
        entity.spatialAudio = SpatialAudioComponent(
            gain: .init(-10),           // Slightly reduced overall volume
            directLevel: .init(-3),     // Strong direct signal for localization
            reverbLevel: .init(-15),    // Lower reverb for more directional feel
            directivity: .beam(focus: 0.7)  // Focused beam for ADC sound
        )
        
        // Start playing the drone sound
        entity.playAudio(audio)
    }
    
    private func playAttachSound(for entity: Entity) {
        // Load the audio source
        guard let audio = try? AudioFileResource.load(
            named: "Sonic_Pulse_Hit_01"
        ) else { return }
        
        // Add spatial audio component with beam directivity
        entity.spatialAudio = SpatialAudioComponent(
            gain: .init(-5),            // Louder than drone but not too loud
            directLevel: .init(-3),     // Clear direct signal
            reverbLevel: .init(-10),    // Moderate reverb for impact feel
            directivity: .beam(focus: 0)  // Zero focus makes it omnidirectional
        )
        
        // Play the attach sound once
        entity.playAudio(audio)
    }
    
    private func triggerCancerDeath(isLeft: Bool) {
        guard let scene = scene else { return }
        let identifier = isLeft ? "cancerDeathLeft" : "cancerDeathRight"
        let notification = Notification(name: .init(rknt),
                                    userInfo: ["\(rknt).Scene" : scene,
                                          "\(rknt).Identifier" : identifier])
        NotificationCenter.default.post(notification)
    }
}

//#Preview(immersionStyle: .mixed) {
//    CurvedPathView()
//        .environment(AppModel())
//}
