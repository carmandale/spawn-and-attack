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

    init() {
        /// register components
        RealityKitContent.AttachmentPoint.registerComponent()
        RealityKitContent.CancerCellComponent.registerComponent()
        RealityKitContent.MovementComponent.registerComponent()
        RealityKitContent.UIAttachmentComponent.registerComponent()
        RealityKitContent.ADCComponent.registerComponent()
        RealityKitContent.BillboardComponent.registerComponent()
        
        /// register systems
        RealityKitContent.AttachmentSystem.registerSystem()
        RealityKitContent.CancerCellSystem.registerSystem()
        RealityKitContent.MovementSystem.registerSystem()
        RealityKitContent.UIAttachmentSystem.registerSystem()
        RealityKitContent.ADCMovementSystem.registerSystem()
        RealityKitContent.BillboardSystem.registerSystem()
    }
    
    @State private var appModel = AppModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.volumetric)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            AttackCancerView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
