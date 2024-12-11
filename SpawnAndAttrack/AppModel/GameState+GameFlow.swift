import SwiftUI
import RealityKitContent
import RealityKit

extension GameState {
    // MARK: - Game Methods
    func startGame() {
        appModel.currentPhase = .playing
        score = 0
        totalHits = 0
        cellsDestroyed = 0
        hasFirstADCBeenFired = false
        completedDeaths.removeAll()
    }
    
    func endGame() {
        appModel.currentPhase = .completed
    }
    
    func resetGameState() {
        score = 0
        totalHits = 0
        cellsDestroyed = 0
        totalADCsDeployed = 0
        hitCounts.removeAll()
        cancerCells.removeAll()
        completedDeaths.removeAll()
        
        appModel.currentPhase = .playing
    }
    
    // MARK: - ADC Tracking
    func incrementADCsDeployed() {
        totalADCsDeployed += 1
    }
    
    // MARK: - Game Conditions
    func checkGameConditions() {
        // Only track destroyed count, completion handled by death notifications
        if cellsDestroyed >= maxCancerCells {
            print("All cells destroyed, waiting for death animations...")
            print(appModel.currentPhase)
            appModel.currentPhase = .completed
            print(appModel.currentPhase)
        }
    }
}
