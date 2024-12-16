import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

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
        case .intro: return "IntroSpace"
        case .lab: return "LabSpace"
        case .building: return "BuildingSpace"
        case .playing, .completed: return "AttackSpace"  // Both use attack space
        case .loading, .error: return ""
        }
    }
}

@Observable @MainActor
final class AppModel {
    // MARK: - Window IDs
    enum WindowID {
        static let debugNavigation = "DebugNavigation"
        static let gameCompleted = "Completed"
        static let main = "MainWindow"
    }

    // MARK: - Properties
    var currentPhase: AppPhase = .loading
    var gameState: GameState
    var isDebugWindowOpen = false

    // MARK: - Immersion Style
    var introStyle: ImmersionStyle = .mixed
    var labStyle: ImmersionStyle = .full
    var buildingStyle: ImmersionStyle = .mixed
    var attackStyle: ImmersionStyle = .full

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
        self.gameState = GameState()
        self.gameState.appModel = self
    }
    
    // MARK: - Phase Management
    func transitionToPhase(_ newPhase: AppPhase) async {
        guard !isTransitioning else { return }
        isTransitioning = true
        print("Transitioning to phase: \(newPhase)")
        currentPhase = newPhase
        currentImmersiveSpace = newPhase.spaceId
        isTransitioning = false
    }
}
