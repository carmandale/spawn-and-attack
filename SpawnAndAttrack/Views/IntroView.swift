//
//  IntroView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 10/23/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

extension Notification.Name {
    static let changeToLabNotification = Notification.Name("ChangeToLab")
}

/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct IntroView: View {
    @Environment(AppModel.self) private var appModel

    /// The root for the follow scene.
    let followRoot: Entity = Entity()
    
    /// The root for the head anchor.
    let headAnchorRoot: Entity = Entity()
    /// The root for the entities in the head-anchored scene.
    let headPositionedEntitiesRoot: Entity = Entity()
    
    /// The root entities for the intro scene.
    let hummingbird: Entity = Entity()
    let immersiveSceneRoot: Entity = Entity()
    
    /// The root entity for other entities within the scene.
    private let root = Entity()
    
    // Create publisher for the notification
    private let changeToLabReceived = NotificationCenter.default.publisher(
        for: .changeToLabNotification
    )

    var body: some View {
        RealityView { content in
            // Add the intro environment to the immersiveSceneRoot
            if let introEnvironmentEntity = await appModel.assetLoadingManager.instantiateEntity("intro_environment") {
                immersiveSceneRoot.addChild(introEnvironmentEntity)
            }
            
            // Create portal and add to immersiveSceneRoot
            // let portal = await PortalManager.createPortal(appModel: appModel)
            // portal.position = [0, 0, -2.5]
            // immersiveSceneRoot.addChild(portal)
            
            // do {
            //     let entity = try await appModel.assetLoadingManager.loadEntity(named: "IntroAudio")
            //     print("Successfully loaded IntroAudio")
            //     immersiveSceneRoot.addChild(entity)
            //     print("Added IntroAudio to immersiveSceneRoot")
            // } catch {
            //     print("Failed to load IntroAudio: \(error)")
            // }
            
            // Add the immersiveSceneRoot to content
            content.add(immersiveSceneRoot)
            
            // Create head anchor for initial Y position only
            // let headAnchor = AnchorEntity(.head)
            // headAnchor.anchoring.trackingMode = .once
            // headAnchor.name = "headAnchor"
            // content.add(headAnchor)
            
            //            headAnchor.addChild(immersiveSceneRoot)
            
            // Get head Y position and offset the entire immersiveSceneRoot
            // let headY = headAnchor.position.y
            // print("Head anchor Y position: \(headY)")
            // print("Current immersiveSceneRoot position before setPosition: \(immersiveSceneRoot.position(relativeTo: nil))")
            // immersiveSceneRoot.setPosition([0, headY, 0], relativeTo: nil)
            // print("Final immersiveSceneRoot position after setPosition: \(immersiveSceneRoot.position(relativeTo: nil))")
            
        }
        .installGestures()
    
        .onReceive(changeToLabReceived) { output in
            print("🎯 Received changeToLab notification")
            guard let entity = output.userInfo?["RealityKit.NotifyAction.SourceEntity"] as? Entity else {
                print("⚠️ No source entity found in notification")
                return
            }
            print("✅ Found source entity: \(entity.name)")
            
            guard appModel.currentPhase == .intro else {
                print("❌ Wrong phase: \(appModel.currentPhase)")
                return
            }
            guard !appModel.isTransitioning else {
                print("❌ Already transitioning")
                return
            }
            
            Task {
                print("🔄 Transitioning to Lab phase")
                await appModel.transitionToPhase(.lab)
            }
        }
    }
}

extension IntroView {
    /// Sets up the follow mode by removing the feeder and adding the hummingbird.
    func startFollowMode() {
        // MARK: Clean up the scene.
        // Find the head anchor in the scene and remove it.
        guard let headAnchor = headAnchorRoot.children.first(where: { $0.name == "headAnchor" }) else { return }
        headAnchorRoot.removeChild(headAnchor)
        
        // Remove the feeder from the view.
        immersiveSceneRoot.removeFromParent()
        
        // MARK: - Create the "follow" scene.
        // Set the position of the root so that the hummingbird flies in from the center.
        followRoot.setPosition([0, 1, -1], relativeTo: nil)
        
        // Rotate the hummingbird to face over the left shoulder, which faces the person due to the offset.
        let orientation = simd_quatf(angle: .pi * -0.15, axis: [0, 1, 0]) * simd_quatf(angle: .pi * 0.2, axis: [1, 0, 0])
        hummingbird.transform.rotation = orientation
        
        // Set the hummingbird as a subentity of its root, and move it to the top-right corner.
        followRoot.addChild(hummingbird)
        hummingbird.setPosition([0.4, 0.2, -1], relativeTo: followRoot)
    }
    
    /// Sets up the head-position mode by enabling the feeder, creating a head anchor, and adding the hummingbird and feeder.
    func startHeadPositionMode(content: RealityViewContent) {
        // Reset the rotation so it aligns with the feeder.
        // hummingbird.transform.rotation = simd_quatf()
        
        // Create an anchor for the head and set the tracking mode to `.once`.
        let headAnchor = AnchorEntity(.head)
        headAnchor.anchoring.trackingMode = .once
        headAnchor.name = "headAnchor"
        // Add the `AnchorEntity` to the scene.
        headAnchorRoot.addChild(headAnchor)
        
        // Add the feeder as a subentity of the root containing the head-positioned entities.
        headPositionedEntitiesRoot.addChild(immersiveSceneRoot)
        
        // Add the hummingbird to the root containing the head-positioned entities and set the position to be further away than the feeder.
        // headPositionedEntitiesRoot.addChild(hummingbird)
        // hummingbird.setPosition([0, 0, -0.15], relativeTo: headPositionedEntitiesRoot)
        
        // Add the head-positioned entities to the anchor, and set the position to be in front of the wearer.
//        headAnchor.addChild(headPositionedEntitiesRoot)
        let newYPosition: Float = -1.0
        let lowerIntroSceneYPosition = headPositionedEntitiesRoot.position.y - newYPosition
        
        headPositionedEntitiesRoot.setPosition([0, lowerIntroSceneYPosition, -0.6], relativeTo: headAnchor)
    }
    
    /// Switches between the follow and head-position modes depending on the `HeadTrackState` case.
    func toggleHeadPositionModeOrFollowMode(content: RealityViewContent) {
        switch appModel.headTrackState {
        case .follow:
            startFollowMode()
        case .headPosition:
            startHeadPositionMode(content: content)
        }
    }

}
