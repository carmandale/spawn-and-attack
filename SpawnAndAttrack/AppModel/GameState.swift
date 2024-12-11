//
//  compliance.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/10/24.
//
import SwiftUI
import RealityKitContent
import RealityKit

@Observable @MainActor
final class GameState: HitCountTracking {
    // MARK: - Core Properties
    var appModel: AppModel!
    var maxCancerCells: Int = 2
    var score: Int = 0
    
    // MARK: - Game Stats and Tracking
    /// Total number of successful hits across all cells
    var totalHits: Int = 0
    /// Number of cells completely destroyed
    var cellsDestroyed: Int = 0
    /// Hit count tracking
    internal var hitCounts: [Int: Int] = [:]
    var totalADCsDeployed: Int = 0
    
    // MARK: - Game Systems
    var cancerCellSystem: CancerCellSystem?
    var adcMovementSystem: ADCMovementSystem?
    
    // MARK: - State
    var hasFirstADCBeenFired: Bool = false
    var cancerCells: [Entity] = []
    internal var completedDeaths: Set<Int> = []
    
    var debounce: [UnorderedPair<Entity>: TimeInterval] = [:]
    static let debounceThreshold: TimeInterval = 0.1
    
    // MARK: - Callbacks
    var onGameStateChanged: ((AppPhase) -> Void)?
    var onScoreChanged: ((Int) -> Void)?
    var onCancerCellSpawned: ((Entity) -> Void)?
    var onCancerCellDestroyed: ((Entity) -> Void)?
    var onADCSpawned: ((Entity) -> Void)?
    var onADCDestroyed: ((Entity) -> Void)?
    
    // MARK: - Initialization
    init() {
        setupNotifications()
        // Add observer for cell death completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCellDeathComplete),
            name: Notification.Name("CellDeathComplete"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
