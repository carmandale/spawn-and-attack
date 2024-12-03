//
//  SpawnAndAttrackApp.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 11/19/24.
//

import SwiftUI
import RealityKitContent

@main
struct SpawnAndAttrackApp: App {
    @State private var appModel = AppModel()

    init() {
        /// Register components and systems
        RealityKitContent.AttachmentPoint.registerComponent()
        RealityKitContent.CancerCellComponent.registerComponent()
        RealityKitContent.MovementComponent.registerComponent()
        RealityKitContent.UIAttachmentComponent.registerComponent()
        RealityKitContent.ADCComponent.registerComponent()
        RealityKitContent.BillboardComponent.registerComponent()
        RealityKitContent.BreathingComponent.registerComponent()
        RealityKitContent.CellPhysicsComponent.registerComponent()
        
        /// Register systems
        RealityKitContent.AttachmentSystem.registerSystem()
        RealityKitContent.BreathingSystem.registerSystem()
        RealityKitContent.CancerCellSystem.registerSystem()
        RealityKitContent.MovementSystem.registerSystem()
        RealityKitContent.UIAttachmentSystem.registerSystem()
        RealityKitContent.ADCMovementSystem.registerSystem()
        RealityKitContent.UIStabilizerSystem.registerSystem()
        RealityKitContent.BillboardSystem.registerSystem()
    }

    var body: some Scene {
        WindowGroup {
            switch appModel.phase {
            case .waitingToStart, .loadingAssets:
                LoadingView()
                    .environment(appModel)
                    .task {
                        await appModel.startLoading()
                    }
            case .intro, .lab, .attack:
                UIPortalView()  // Will be our intro view
                    .environment(appModel)
            }
        }
       .windowStyle(.volumetric)

        // Immersive space for LabView
        ImmersiveSpace(id: "LabSpace") {
            LabView()
                .environment(appModel)
        }

        // Immersive space for AttackCancerView
        ImmersiveSpace(id: "AttackCancerSpace") {
            AttackCancerView()
                .environment(appModel)
        }

        /// Register the Intro immersive space.
        ImmersiveSpace(id: "IntroSpace") {
            IntroView()
                .environment(appModel)
        }
    }
}
