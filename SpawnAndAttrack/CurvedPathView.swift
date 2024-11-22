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
                print("Immersive content loaded")
                
                // Find and setup left cancer cell
                if let leftCell = immersiveContentEntity.findEntity(named: "cancerCell_left") {
                    print("Found left cancer cell")
                    if let leftMeter = attachments.entity(for: "leftMeter") {
                        print("Left meter attachment found")
                        leftMeter.position = [0, 0.5, 0]
                        leftCell.addChild(leftMeter)
                    }
                    
                    // Find all attachment points for left cell
                    findAttachmentPoints(in: leftCell) { points in
                        leftCellAttachPoints = points
                        print("Found \(points.count) attachment points for left cell")
                        // Map all left cell attachment points
                        points.forEach { attachmentCellMap[$0] = true }
                        for point in points {
                            print("Left cell attachment point: \(point.name)")
                        }
                    }
                }
                
                // Find and setup right cancer cell
                if let rightCell = immersiveContentEntity.findEntity(named: "cancerCell_right") {
                    print("Found right cancer cell")
                    if let rightMeter = attachments.entity(for: "rightMeter") {
                        print("Right meter attachment found")
                        rightMeter.position = [0, 0.5, 0]
                        rightCell.addChild(rightMeter)
                    }
                    
                    // Find all attachment points for right cell
                    findAttachmentPoints(in: rightCell) { points in
                        rightCellAttachPoints = points
                        print("Found \(points.count) attachment points for right cell")
                        // Map all right cell attachment points
                        points.forEach { attachmentCellMap[$0] = false }
                        for point in points {
                            print("Right cell attachment point: \(point.name)")
                        }
                    }
                }
            }
            
            // Load the ADC entity
            if let adc = try? await Entity(named: "ADC-spawn", in: realityKitContentBundle) {
                adcEntity = adc
                print("ADC entity loaded successfully in RealityView setup.")
            } else {
                print("Failed to load ADC entity.")
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
                    print("Tap gesture recognized")
                    handleTap(on: value.entity)
                }
        )
    }
    
    private func findAttachmentPoints(in entity: Entity, completion: @escaping ([Entity]) -> Void) {
        var points: [Entity] = []
        
        func recursiveSearch(_ entity: Entity) {
            // Print the current entity name for debugging
            print("Searching entity: \(entity.name)")
            
            // Check all children recursively
            for child in entity.children {
                if child.name.lowercased().contains("attach") {
                    print("Found attachment point: \(child.name)")
                    points.append(child)
                }
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
        print("Handling tap on entity: \(entity.name)")
        
        let isLeftCell = entity.name.contains("left")
        guard let attachPoint = getAvailableAttachPoint(isLeft: isLeftCell) else {
            print("No available attachment points")
            return
        }
        
        let worldPosition = attachPoint.convert(position: .zero, to: nil)
        print("Target position: \(worldPosition)")
        
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
        guard let root = rootEntity, let adcTemplate = adcEntity else {
            print("Root entity or ADC template not available.")
            return
        }
        
        // Clone the preloaded entity to avoid reusing the same instance
        let adc = adcTemplate.clone(recursive: true)
        root.addChild(adc)
        
        // Set initial position
        adc.position = start
        print("Spawned ADC at position: \(start)")
        
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
            print("Target entity name: \(targetEntity.name)")
            let isLeft = attachmentCellMap[targetEntity] ?? false
            print("Is left cell? \(isLeft)")
            if isLeft {
                leftCellHits = min(leftCellHits + 1, 18)
                print("Left cell hit: \(leftCellHits)")
            } else {
                rightCellHits = min(rightCellHits + 1, 18)
                print("Right cell hit: \(rightCellHits)")
            }
            // Attach ADC to the attachment point
            adc.position = .zero
            targetEntity.addChild(adc)
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
}

//#Preview(immersionStyle: .mixed) {
//    CurvedPathView()
//        .environment(AppModel())
//}
