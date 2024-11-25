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
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    // Game state
    var score = 0
    var totalHits = 0
    var cellsDestroyed = 0
    
    func incrementScore(by points: Int = 1) {
        score += points
    }
}
