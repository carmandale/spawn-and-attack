//
//  LabView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 10/23/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct LabView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    // @StateObject private var headTracker = {
    //     let tracker = HeadTracker()
    //     tracker.config.heightOffset = -1.0  // Set desired offset
    //     return tracker
    // }()
    
    // Store subscription to prevent deallocation
    @State private var subscription: EventSubscription?
    
    // Hand tracking for debug window
    //    @State var handTrackedEntity: Entity = {
    //        let handAnchor = AnchorEntity(.hand(.left, location: .aboveHand))
    //        return handAnchor
    //    }()
    
    var body: some View {
        RealityView { content, attachments in
            do {
                // Create lab root
                let root = Entity()
                content.add(root)
                // Load lab environment first
                guard let labEnvironment = await appModel.assetLoadingManager.instantiateEntity("lab_environment") else {
                    print("Failed to load LabEnvironment from asset manager")
                    return
                }
                
                
                root.addChild(labEnvironment)
                
                
                // Create head anchor for one-time positioning
                // let headAnchor = headTracker.getInitialHeadAnchor()
                // let labRoot = Entity()  // Intermediate root for positioning
                // headAnchor.addChild(labRoot)
                // labRoot.setPosition([0, -1.0, -0.6], relativeTo: headAnchor)  // Position relative to head
                
                // Add lab environment to positioned root
                // labRoot.addChild(root)
                // content.add(labRoot)
                // content.add(headAnchor)
                
                // Add hand tracked debug window
                //                content.add(handTrackedEntity)
                //                if let attachmentEntity = attachments.entity(for: "DebugNavigation") {
                ////                    attachmentEntity.components[BillboardComponent.self] = .init()
                //                    handTrackedEntity.addChild(attachmentEntity)
                //                }
                
                // Setup collision tracking separately
                // let collisionEntity = headTracker.setupCollisionTracking()
                // let collisionRoot = Entity()
                // collisionRoot.components.set(ClosureComponent(closure: { deltaTime in
                //     guard let transform = headTracker.worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())?.originFromAnchorTransform else { return }
                //     let targetPosition = transform.translation() - Float3(0, 0, 0)
                //     collisionEntity.setPosition(targetPosition, relativeTo: nil)
                // }))
                // collisionRoot.addChild(collisionEntity)
                // content.add(collisionRoot)
                
                // Then subscribe to collision events
                subscription = content.subscribe(to: CollisionEvents.Began.self) { [weak appModel] event in
                    appModel?.handleCollisionBegan(event)
                }
            }
            //            } catch {
            //                print("Failed to load lab environment: \(error)")
            //            }
        } update: { content, attachments in
            // Update content
        } attachments: {
            // Attachment(id: "DebugNavigation") {
            //     DebugNavigationWindow()
            // }
        }
        .installGestures()
        .task {
            // await headTracker.startTracking()
        }
        .onAppear {
            // When lab space becomes active, open ADC builder
            //     openWindow(id: AppModel.WindowState.adcBuilder.windowId)
            //     appModel.isShowingADCBuilder = true
            // }
            //        .onDisappear {
            //            // Stop head tracking
            //            // headTracker.stopTracking()
            //
            //            // Clear collision subscription
            //            subscription?.cancel()
            //            subscription = nil
            //
            //            // When lab space becomes inactive, close all associated windows
            //            // if appModel.isShowingADCVolumetric {
            //            //     dismissWindow(id: AppModel.WindowState.adcVolumetric.windowId)
            //            //     appModel.isShowingADCVolumetric = false
            //            // }
            //            // if appModel.isShowingADCBuilder {
            //            //     dismissWindow(id: AppModel.WindowState.adcBuilder.windowId)
            //            //     appModel.isShowingADCBuilder = false
            //            // }
            //        }
        }
    }
}
