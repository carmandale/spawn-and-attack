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
    @State private var handTracking = HandTrackingViewModel()
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow) var dismissWindow
    @Environment(\.openWindow) var openWindow
    
    init() {
        /// Register components and systems
        RealityKitContent.AttachmentPoint.registerComponent()
        RealityKitContent.CancerCellComponent.registerComponent()
        RealityKitContent.CancerCellStateComponent.registerComponent()
        RealityKitContent.MovementComponent.registerComponent()
        RealityKitContent.UIAttachmentComponent.registerComponent()
        RealityKitContent.ADCComponent.registerComponent()
        RealityKitContent.BreathingComponent.registerComponent()
        RealityKitContent.CellPhysicsComponent.registerComponent()
        RealityKitContent.MicroscopeViewerComponent.registerComponent()
        RealityKitContent.GestureComponent.registerComponent()
        RealityKitContent.AntigenComponent.registerComponent()
        
        // Register UI sync components and system
        HitCountComponent.registerComponent()
        UIStateSyncSystem.registerSystem()

        /// Register systems
        AttachmentSystem.registerSystem()
        BreathingSystem.registerSystem()
        CancerCellSystem.registerSystem()
        MovementSystem.registerSystem()
        UIAttachmentSystem.registerSystem()
        ADCMovementSystem.registerSystem()
        UIStabilizerSystem.registerSystem()
        AntigenSystem.registerSystem()
        
        // Add ClosureSystem registration
        ClosureSystem.registerSystem()
        ClosureComponent.registerComponent()
        
        // Add HeadTracking FollowSystem
        FollowSystem.registerSystem()
        FollowComponent.registerComponent()
    }
    


    var body: some Scene {
        // Main Content Window
        WindowGroup(id: AppModel.mainWindowId) {
            ContentView()
                .environment(appModel)
        }
        .defaultSize(CGSize(width: 800, height: 600))
        .windowStyle(.plain)
        .windowResizability(.contentSize)

        // Intro Window
        WindowGroup(id: AppModel.introWindowId) {
            IntroWindowView()
        }
        .defaultSize(CGSize(width: 600, height: 300))
        .windowStyle(.plain)
        
        // Debug Navigation Window 
        WindowGroup(id: AppModel.debugNavigationWindowId) {
            DebugNavigationWindow()
                .environment(appModel)
        }
        .defaultSize(CGSize(width: 400, height: 800))

        
        // Completed View
        WindowGroup(id: AppModel.gameCompletedWindowId) {
            CompletedView()
                .environment(appModel)
        }

        // Library Window
        WindowGroup(id: AppModel.libraryWindowId) {
            LibraryView()
                .environment(appModel)
        }
        .defaultSize(CGSize(width: 800, height: 600))

        /// MARK: - Immersive Spaces
        // Immersive Spaces
        ImmersiveSpace(id: "IntroSpace") {
            IntroView()
                .environment(appModel)
        }
        .immersionStyle(selection: $appModel.introStyle, in: .mixed)

        ImmersiveSpace(id: "LabSpace") {
            LabView()
                .environment(appModel)
        }
        .immersionStyle(selection: $appModel.labStyle, in: .full)
        .upperLimbVisibility(.visible)

        ImmersiveSpace(id: "BuildingSpace") {
            BuildADCEnvironmentView()
                .environment(appModel)
        }
        .immersionStyle(selection: $appModel.buildingStyle, in: .mixed)

        ImmersiveSpace(id: "AttackSpace") {
            AttackCancerView()
                .environment(appModel)
                .environment(handTracking)
        }
        .immersionStyle(selection: $appModel.attackStyle, in: .progressive)
        .upperLimbVisibility(.automatic)

        // Single onChange handler for phase transitions
        .onChange(of: appModel.currentPhase) { oldPhase, newPhase in
            if oldPhase == newPhase { return }  // Skip if no actual change
            print("SpawnAndAttrackApp: Changing phase from \(oldPhase) to \(newPhase)")
            
            Task {
                // If transitioning from loading, dismiss main window
                if oldPhase == .loading {
                    dismissWindow(id: AppModel.mainWindowId)
                }
                
                // Handle window visibility based on phase
                switch newPhase {
                case .loading:
                    // Close other windows
                    if appModel.isIntroWindowOpen {
                        dismissWindow(id: AppModel.introWindowId)
                        appModel.isIntroWindowOpen = false
                    }
                    if appModel.isLibraryWindowOpen {
                        dismissWindow(id: AppModel.libraryWindowId)
                        appModel.isLibraryWindowOpen = false
                    }
                    if appModel.isDebugWindowOpen {
                        dismissWindow(id: AppModel.debugNavigationWindowId)
                        appModel.isDebugWindowOpen = false
                    }
                    
                case .intro:
                    // Show intro window in intro phase
                    if !appModel.isIntroWindowOpen {
                        openWindow(id: AppModel.introWindowId)
                        appModel.isIntroWindowOpen = true
                    }
                    if !appModel.isDebugWindowOpen {
                        openWindow(id: AppModel.debugNavigationWindowId)
                        appModel.isDebugWindowOpen = true
                    }
                    // Ensure library is closed
                    if appModel.isLibraryWindowOpen {
                        dismissWindow(id: AppModel.libraryWindowId)
                        appModel.isLibraryWindowOpen = false
                    }
                
                case .playing:
                    // Hide all windows except game windows in attack phase
                    if appModel.isIntroWindowOpen {
                        dismissWindow(id: AppModel.introWindowId)
                        appModel.isIntroWindowOpen = false
                    }
                    if appModel.isDebugWindowOpen {
                        dismissWindow(id: AppModel.debugNavigationWindowId)
                        appModel.isDebugWindowOpen = false
                    }
                    if appModel.isLibraryWindowOpen {
                        dismissWindow(id: AppModel.libraryWindowId)
                        appModel.isLibraryWindowOpen = false
                    }
                    
                case .completed:
                    // Hide windows and show completed window
                    if appModel.isIntroWindowOpen {
                        dismissWindow(id: AppModel.introWindowId)
                        appModel.isIntroWindowOpen = false
                    }
                    if appModel.isLibraryWindowOpen {
                        dismissWindow(id: AppModel.libraryWindowId)
                        appModel.isLibraryWindowOpen = false
                    }
                    if !appModel.isDebugWindowOpen {
                        openWindow(id: AppModel.debugNavigationWindowId)
                        appModel.isDebugWindowOpen = true
                    }
                    openWindow(id: AppModel.gameCompletedWindowId)
                    return // Don't dismiss or change immersive space during completion
                    
                case .lab:
                    // Open library window in lab phase
                    if appModel.isIntroWindowOpen {
                        dismissWindow(id: AppModel.introWindowId)
                        appModel.isIntroWindowOpen = false
                    }
                    if !appModel.isLibraryWindowOpen {
                        openWindow(id: AppModel.libraryWindowId)
                        appModel.isLibraryWindowOpen = true
                    }
                    if !appModel.isDebugWindowOpen {
                        openWindow(id: AppModel.debugNavigationWindowId)
                        appModel.isDebugWindowOpen = true
                    }
                    
                default:
                    // Hide all windows except debug navigation in all other phases
                    if appModel.isIntroWindowOpen {
                        dismissWindow(id: AppModel.introWindowId)
                        appModel.isIntroWindowOpen = false
                    }
                    if appModel.isLibraryWindowOpen {
                        dismissWindow(id: AppModel.libraryWindowId)
                        appModel.isLibraryWindowOpen = false
                    }
                    if !appModel.isDebugWindowOpen {
                        openWindow(id: AppModel.debugNavigationWindowId)
                        appModel.isDebugWindowOpen = true
                    }
                }
                
                // Always dismiss the completed window if not in completed phase
                if newPhase != .completed {
                    dismissWindow(id: AppModel.gameCompletedWindowId)
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

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: UIApplication) -> Bool {
        return true
    }
}
