import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

// MARK: - App Constants
extension AppModel {
    static let mainWindowId = "MainWindow"
    static let introWindowId = "IntroWindow"
    static let libraryWindowId = "Library"
    static let debugNavigationWindowId = "DebugNavigation"
    static let gameCompletedWindowId = "Completed"
    
    static let introSpaceId = "IntroSpace"
    static let labSpaceId = "LabSpace"
    static let buildingSpaceId = "BuildingSpace"
    static let attackSpaceId = "AttackSpace"
}

enum AppPhase: String, CaseIterable, Codable, Sendable, Equatable {
    case loading
    case intro
    case lab
    case building
    case playing
    case completed
    case error
    
    var needsImmersiveSpace: Bool {
        return self != .loading && self != .error
    }
    
    var spaceId: String {
        switch self {
        case .intro: return AppModel.introSpaceId
        case .lab: return AppModel.labSpaceId
        case .building: return AppModel.buildingSpaceId
        case .playing, .completed: return AppModel.attackSpaceId
        case .loading, .error: return ""
        }
    }
    
    var windowId: String {
        switch self {
        case .loading: return AppModel.mainWindowId
        case .intro: return AppModel.introWindowId
        case .completed: return AppModel.gameCompletedWindowId
        case .lab: return AppModel.libraryWindowId
        case .building, .playing, .error: return ""
        }
    }
}

@Observable @MainActor
final class AppModel {
    // MARK: - Properties
    var currentPhase: AppPhase = .loading
    var gameState: AttackCancerViewModel
    var handTracking: HandTrackingViewModel
    var isDebugWindowOpen = false
    var isLibraryWindowOpen = false
    var isIntroWindowOpen = false

    // MARK: - Immersion Style
    var introStyle: ImmersionStyle = .mixed
    var labStyle: ImmersionStyle = .full
    var buildingStyle: ImmersionStyle = .mixed
    var attackStyle: ImmersionStyle = .progressive(
        0.1...1.0,
        initialAmount: 0.65
    )

    // MARK: - Asset Management
    let assetLoadingManager = AssetLoadingManager.shared
    var loadingProgress: Float = 0
    var isLoading = false

    var headTrackState: HeadTrackState = .headPosition

    /// Track the state of the toggle.
    /// Follow: Uses `queryDeviceAnchor` to follow the device's position.
    /// HeadPosition: Uses `AnchorEntity` to launch at the head position in front of the wearer.
    enum HeadTrackState: String, CaseIterable {
        case follow
        case headPosition = "head-position"
    }
    
    // MARK: - Space Management
    @ObservationIgnored private var currentImmersiveSpace: String?
    @ObservationIgnored private(set) var isTransitioning = false
    
    var isInImmersiveSpace: Bool {
        return currentImmersiveSpace != nil
    }
    
    // MARK: - Initialization
    init() {
        self.handTracking = HandTrackingViewModel()
        self.gameState = AttackCancerViewModel()
        self.gameState.appModel = self
        self.gameState.handTracking = self.handTracking
    }
    
    // MARK: - Phase Management
    func transitionToPhase(_ newPhase: AppPhase) async {
        guard !isTransitioning else { return }
        isTransitioning = true
        print("Transitioning to phase: \(newPhase)")
        
        let oldPhase = currentPhase
        currentPhase = newPhase
        
        // Handle window transitions
        if !oldPhase.windowId.isEmpty {
            // Removed window management implementation
        }
        if !newPhase.windowId.isEmpty {
            // Removed window management implementation
        }
        
        currentImmersiveSpace = newPhase.spaceId
        // Add delay to ensure space is loaded before allowing another transition
        try? await Task.sleep(for: .seconds(0.5))
        isTransitioning = false
    }
}
