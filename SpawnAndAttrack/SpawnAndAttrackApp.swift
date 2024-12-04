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
        // Main Content Window - Left unchanged, preserving volumetric style
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.volumetric)

        // Debug Navigation Window - Adjusted to match Garden14 pattern
        WindowGroup(id: "DebugNavigation") {
            DebugNavigationWindow()
                .environment(appModel)
        }
        // .defaultSize(CGSize(width: 300, height: 200))
        // Removed unnecessary modifiers

        // ADC Builder Window - Left unchanged
        WindowGroup(id: "ADCBuilder") {
            BuildADCView()
                .environment(appModel)
        }

        // ADC Volumetric Window
        WindowGroup(id: "ADCVolumetric") {
            ADCVolumetricView()
                .environment(appModel)
        }
        .windowStyle(.volumetric)

        // Immersive Spaces
        ImmersiveSpace(id: AppModel.SpaceState.intro.spaceId) {
            IntroView()
                .environment(appModel)
        }

        ImmersiveSpace(id: AppModel.SpaceState.lab.spaceId) {
            LabView()
                .environment(appModel)
        }

        ImmersiveSpace(id: AppModel.SpaceState.attack.spaceId) {
            AttackCancerView()
                .environment(appModel)
        }
    }
}