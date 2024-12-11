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
    @Environment(\.dismissWindow) var dismissWindow
    @Environment(\.openWindow) var openWindow
    
    init() {
        /// Register components and systems
        RealityKitContent.AttachmentPoint.registerComponent()
        RealityKitContent.CancerCellComponent.registerComponent()
        RealityKitContent.MovementComponent.registerComponent()
        RealityKitContent.UIAttachmentComponent.registerComponent()
        RealityKitContent.ADCComponent.registerComponent()
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
        
        // Add ClosureSystem registration
        ClosureSystem.registerSystem()
        
        // Add HeadTracking FollowSystem
        FollowSystem.registerSystem()
        FollowComponent.registerComponent()
    }
    
    let heightModifier: CGFloat = 0.25

    var body: some Scene {
        // Main Content Window
        WindowGroup(id: AppModel.WindowID.main) {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.plain)

        // Debug Navigation Window 
        WindowGroup(id: AppModel.WindowID.debugNavigation) {
            DebugNavigationWindow()
                .environment(appModel)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(CGSize(width: 150, height: 400))
        
        // Completed View
        WindowGroup(id: AppModel.WindowID.gameCompleted) {
            CompletedView()
                .environment(appModel)
        }
        .windowStyle(.plain)
        
        /// MARK: - Immersive Spaces
        // Immersive Spaces
        ImmersiveSpace(id: "IntroSpace") {
            IntroView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.full), in: .mixed)

        ImmersiveSpace(id: "LabSpace") {
            LabView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
        .upperLimbVisibility(.visible)

        ImmersiveSpace(id: "BuildingSpace") {
            BuildADCEnvironmentView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.full), in: .mixed)

        ImmersiveSpace(id: "AttackSpace") {
            AttackCancerView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
        .upperLimbVisibility(.automatic)

        // Single onChange handler for phase transitions
        .onChange(of: appModel.currentPhase) { oldPhase, newPhase in
            if oldPhase == newPhase { return }  // Skip if no actual change
            print("Transitioning to phase: \(newPhase)")
            
            Task {
                // Handle window visibility based on phase
                switch newPhase {
                case .intro:
                    // Show main window in intro phase
                    openWindow(id: AppModel.WindowID.main)
                    if !appModel.isDebugWindowOpen {
                        openWindow(id: AppModel.WindowID.debugNavigation)
                        appModel.isDebugWindowOpen = true
                    }
                
                case .playing:
                    // Hide main window and debug navigation in attack phase
                    dismissWindow(id: AppModel.WindowID.main)
                    dismissWindow(id: AppModel.WindowID.debugNavigation)
                    appModel.isDebugWindowOpen = false
                case .completed:
                    // Hide main window, show debug navigation and completed window
                    dismissWindow(id: AppModel.WindowID.main)
                    if !appModel.isDebugWindowOpen {
                        openWindow(id: AppModel.WindowID.debugNavigation)
                        appModel.isDebugWindowOpen = true
                    }
                    openWindow(id: AppModel.WindowID.gameCompleted)
                    return // Don't dismiss or change immersive space during completion
                default:
                    // Hide main window, show debug navigation in all other phases
                    dismissWindow(id: AppModel.WindowID.main)
                    if !appModel.isDebugWindowOpen {
                        openWindow(id: AppModel.WindowID.debugNavigation)
                        appModel.isDebugWindowOpen = true
                    }
                }
                
                // Always dismiss the completed window if not in completed phase
                if newPhase != .completed {
                    dismissWindow(id: AppModel.WindowID.gameCompleted)
                }
                
                // Always dismiss the current space first
                if oldPhase.needsImmersiveSpace {
                    await dismissImmersiveSpace()
                }
                
                // Then open the new space if needed
                if newPhase.needsImmersiveSpace {
                    let spaceId = newPhase.spaceId
                    switch await openImmersiveSpace(id: spaceId) {
                    case .opened:
                        print("Successfully opened space: \(spaceId)")
                    case .error:
                        print("Error opening space: \(spaceId)")
                    case .userCancelled:
                        print("User cancelled opening space: \(spaceId)")
                    @unknown default:
                        print("Unknown result opening space: \(spaceId)")
                    }
                }
            }
        }
    }
}
