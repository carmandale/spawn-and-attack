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
    
    var body: some View {
        RealityView { content, attachments in
            // Create root entity
            let root = Entity()
            content.add(root)
            appModel.gameState.setRootEntity(root)
            
            // Load the immersive content if available
            Task {
                if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    root.addChild(immersiveContentEntity)
                    
                    // Find and setup left cancer cell
                    if let leftCell = immersiveContentEntity.findEntity(named: "cancerCell_left") {
                        if let leftMeter = attachments.entity(for: "leftMeter") {
                            leftMeter.position = [0, 0.5, 0]
                            leftCell.addChild(leftMeter)
                        }
                        
                        // Register left cell attachment points
                        appModel.gameState.registerAttachmentPoints(for: leftCell, isLeftCell: true)
                    }
                    
                    // Find and setup right cancer cell
                    if let rightCell = immersiveContentEntity.findEntity(named: "cancerCell_right") {
                        if let rightMeter = attachments.entity(for: "rightMeter") {
                            rightMeter.position = [0, 0.5, 0]
                            rightCell.addChild(rightMeter)
                        }
                        
                        // Register right cell attachment points
                        appModel.gameState.registerAttachmentPoints(for: rightCell, isLeftCell: false)
                    }
                    
                    // Load ADC template
                    if let adcTemplate = try? await Entity(named: "ADC", in: realityKitContentBundle) {
                        appModel.gameState.setADCTemplate(adcTemplate)
                    }
                }
            }
        } attachments: {
            Attachment(id: "leftMeter") {
                ProgressView(value: Float(appModel.gameState.leftCellHits) / Float(appModel.gameState.maxHitsPerCell))
                    .progressViewStyle(.linear)
                    .frame(width: 0.2, height: 0.02)
            }
            Attachment(id: "rightMeter") {
                ProgressView(value: Float(appModel.gameState.rightCellHits) / Float(appModel.gameState.maxHitsPerCell))
                    .progressViewStyle(.linear)
                    .frame(width: 0.2, height: 0.02)
            }
        }
        .gesture(dragGesture)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                handleDrag(value)
            }
            .onEnded { value in
                handleDragEnd(value)
            }
    }
    
    private func handleDrag(_ value: EntityTargetValue<DragGesture.Value>) {
        guard appModel.gameState.phase == .playing,
              let scene = scene else { return }
        
        let location = value.location3D
        
        // Find available attachment point
        if let targetEntity = AttachmentSystem.getAvailablePoint(in: scene, isLeft: location.x < 0),
           appModel.gameState.isAttachPointAvailable(targetEntity) {
            
            // Get ADC template and spawn new instance
            guard let adcTemplate = appModel.gameState.adcTemplateEntity else { return }
            let adc = adcTemplate.clone(recursive: true)
            
            // Start animation
            spawnAndAnimateCubeWithCurvedPath(from: location, to: targetEntity.position(relativeTo: nil), targetEntity: targetEntity)
        }
    }
    
    private func handleDragEnd(_ value: EntityTargetValue<DragGesture.Value>) {
        // Handle drag end if needed
    }
    
    private func spawnAndAnimateCubeWithCurvedPath(from start: SIMD3<Float>, to end: SIMD3<Float>, targetEntity: Entity) {
        guard let root = appModel.gameState.rootEntity,
              let adcTemplate = appModel.gameState.adcTemplateEntity else { return }
        
        // Clone the preloaded entity to avoid reusing the same instance
        let adc = adcTemplate.clone(recursive: true)
        
        // Initial setup
        adc.position = start
        root.addChild(adc)
        
        // Generate control points for curved path
        let controlPoint1 = SIMD3<Float>(start.x, start.y + 0.5, start.z)
        let controlPoint2 = SIMD3<Float>(end.x, end.y + 0.5, end.z)
        
        // Create the animation
        let duration: TimeInterval = 2.0
        let numberOfPoints = 60
        var keyframes: [Transform] = []
        
        for i in 0...numberOfPoints {
            let t = Float(i) / Float(numberOfPoints)
            let position = cubicBezier(t: t, p0: start, p1: controlPoint1, p2: controlPoint2, p3: end)
            keyframes.append(Transform(scale: .one, rotation: .init(), translation: position))
        }
        
        // Play the animation
        adc.move(
            along: try! AnimationKeyframeSequence(keyframes),
            duration: duration,
            bindTarget: .transform
        )
        
        // Handle attachment on completion
        Task {
            try? await Task.sleep(for: .seconds(duration))
            
            // Mark the attachment point as used
            appModel.gameState.markAttachPointUsed(targetEntity)
            AttachmentSystem.markPointAsOccupied(targetEntity, connectedEntity: adc)
            
            // Update game state
            let isLeft = targetEntity.components[AttachmentStateComponent.self]?.isLeft ?? false
            appModel.gameState.incrementHits(isLeftCell: isLeft)
        }
    }
    
    private func cubicBezier(t: Float, p0: SIMD3<Float>, p1: SIMD3<Float>, p2: SIMD3<Float>, p3: SIMD3<Float>) -> SIMD3<Float> {
        let oneMinusT = 1 - t
        let oneMinusT2 = oneMinusT * oneMinusT
        let oneMinusT3 = oneMinusT2 * oneMinusT
        let t2 = t * t
        let t3 = t2 * t
        
        return oneMinusT3 * p0 +
            3 * oneMinusT2 * t * p1 +
            3 * oneMinusT * t2 * p2 +
            t3 * p3
    }
}
