//
//  AppModel.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 11/19/24.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    // MARK: - Properties
    var immersiveSpaceState = ImmersiveSpaceState.closed {
        didSet {
            if immersiveSpaceState == .open {
                gameState.startGame()
                setupSystems()
            } else if immersiveSpaceState == .closed {
                gameState.endGame()
                cleanupSystems()
            }
        }
    }
    
    // MARK: - Game State
    let gameState: GameState
    private var adcSystem: ADCSystem?
    
    // MARK: - Initialization
    init() {
        self.gameState = GameState()
    }
    
    // MARK: - Game Control
    func pauseGame() {
        gameState.pauseGame()
    }
    
    func resumeGame() {
        gameState.resumeGame()
    }
    
    func restartGame() {
        gameState.startGame()
    }
    
    // MARK: - Systems Management
    private func setupSystems() {
        guard let scene = gameState.scene else { return }
        
        // Create and register ADC system
        let adcSystem = ADCSystem(scene: scene)
        scene.subscribe(to: SceneEvents.Update.self) { [weak adcSystem] event in
            adcSystem?.update(context: event)
        }
        self.adcSystem = adcSystem
    }
    
    private func cleanupSystems() {
        guard let scene = gameState.scene else { return }
        
        // Unsubscribe ADC system
        scene.unsubscribe(self.adcSystem)
        self.adcSystem = nil
    }
}
