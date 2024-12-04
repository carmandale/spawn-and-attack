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
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        RealityView { content in
            // Create the root entity for our lab environment
            let root = Entity()
            do {
                try await createEnvironment(on: root, appModel: appModel)
            } catch {
                print("Failed to load environment: \(error.localizedDescription)")
            }
            
            content.add(root)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // When lab space becomes active, open ADC builder
                openWindow(id: AppModel.WindowState.adcBuilder.windowId)
                appModel.isShowingADCBuilder = true
            case .inactive, .background:
                // When lab space becomes inactive, close all associated windows
                if appModel.isShowingADCVolumetric {
                    dismissWindow(id: AppModel.WindowState.adcVolumetric.windowId)
                    appModel.isShowingADCVolumetric = false
                }
                if appModel.isShowingADCBuilder {
                    dismissWindow(id: AppModel.WindowState.adcBuilder.windowId)
                    appModel.isShowingADCBuilder = false
                }
            @unknown default:
                break
            }
        }
    }
}
