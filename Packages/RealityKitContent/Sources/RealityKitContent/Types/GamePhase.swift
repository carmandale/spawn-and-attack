/*
Abstract:
Defines the different phases of the ADC targeting game.
*/

import Foundation

public enum GamePhase: Sendable {
    case setup
    case playing
    case paused
    case completed
}
