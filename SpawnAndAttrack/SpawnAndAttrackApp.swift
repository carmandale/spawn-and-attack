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
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
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
        RealityKitContent.MicroscopeViewerComponent.registerComponent()
        RealityKitContent.GestureComponent.registerComponent()
        
        /// Register systems
        RealityKitContent.AttachmentSystem.registerSystem()
        RealityKitContent.BreathingSystem.registerSystem()
        RealityKitContent.CancerCellSystem.registerSystem()
        RealityKitContent.MovementSystem.registerSystem()
        RealityKitContent.UIAttachmentSystem.registerSystem()
        RealityKitContent.ADCMovementSystem.registerSystem()
        RealityKitContent.UIStabilizerSystem.registerSystem()
        RealityKitContent.BillboardSystem.registerSystem()
        
        // Add ClosureSystem registration
        ClosureSystem.registerSystem()
    }
    
    let heightModifier: CGFloat = 0.25

    var body: some Scene {
        // Main Content Window - Left unchanged, preserving volumetric style
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.volumetric)

        // Debug Navigation Window - Adjusted to match Garden14 pattern
        WindowGroup(id: AppModel.WindowState.debugNavigation.windowId) {
            DebugNavigationWindow()
                .environment(appModel)
        }.windowResizability(.contentMinSize)
         .defaultSize(CGSize(width: 150, height: 400))
        // Removed unnecessary modifiers

        // ADC Builder Window - Left unchanged
        WindowGroup(id: AppModel.WindowState.adcBuilder.windowId) {
            BuildADCView()
                .environment(appModel)
        }

        // ADC Volumetric Window
        WindowGroup(id: AppModel.WindowState.adcVolumetric.windowId) {
            ADCVolumetricView()
                .environment(appModel)
        }
        .windowStyle(.volumetric)
        .defaultWindowPlacement { _, context in
            if let mainWindow = context.windows.first {
                return WindowPlacement(.leading(mainWindow))
            }
            return WindowPlacement(.none)
        }
        

        // Immersive Spaces
        ImmersiveSpace(id: AppModel.SpaceState.intro.spaceId) {
            IntroView()
                .environment(appModel)
        }

        ImmersiveSpace(id: AppModel.SpaceState.lab.spaceId) {
            LabView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
        .upperLimbVisibility(.visible)

        ImmersiveSpace(id: AppModel.SpaceState.bloodVessel.spaceId) {
            BloodVesselView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
        .upperLimbVisibility(.visible)

        ImmersiveSpace(id: AppModel.SpaceState.attack.spaceId) {
            AttackCancerView()
                .environment(appModel)
        }

        
        .onChange(of: appModel.gamePhase) { _, newPhase in
            if newPhase == .playing && !appModel.immersiveSpaceActive {
                Task {
                    switch await openImmersiveSpace(id: AppModel.SpaceState.intro.spaceId) {
                    case .opened:
                        appModel.introSpaceActive = true
                        appModel.currentPhase = .intro
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        appModel.introSpaceActive = false
                    }
                }
            }
        }
        
        // Handle phase transitions
        .onChange(of: appModel.currentPhase) { oldPhase, newPhase in
            if oldPhase == newPhase { return }  // Skip if no actual change
            Task {
                switch newPhase {
                case .intro:
                    await dismissImmersiveSpace()
                    switch await openImmersiveSpace(id: AppModel.SpaceState.intro.spaceId) {
                    case .opened:
                        appModel.introSpaceActive = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        appModel.introSpaceActive = false
                    }
                    
                case .lab:
                    await dismissImmersiveSpace()
                    switch await openImmersiveSpace(id: AppModel.SpaceState.lab.spaceId) {
                    case .opened:
                        appModel.labSpaceActive = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        appModel.labSpaceActive = false
                    }

                case .bloodVessel:
                    await dismissImmersiveSpace()
                    switch await openImmersiveSpace(id: AppModel.SpaceState.bloodVessel.spaceId) {
                    case .opened:
                        appModel.bloodVesselSpaceActive = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        appModel.bloodVesselSpaceActive = false
                    }
                    
                case .attack:
                    await dismissImmersiveSpace()
                    switch await openImmersiveSpace(id: AppModel.SpaceState.attack.spaceId) {
                    case .opened:
                        appModel.attackSpaceActive = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        appModel.attackSpaceActive = false
                    }
                }
            }
        }
    }
}
