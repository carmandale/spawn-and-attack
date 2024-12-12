/*
See LICENSE.txt file for this sample's licensing information.

Abstract:
Component that tracks ADC (Antibody-Drug Conjugate) state and movement parameters.
*/

import RealityKit
import Foundation

/// Component that defines ADC behavior and movement parameters
public struct ADCComponent: Component, Codable {
    /// Current state of the ADC
    public enum State: String, Codable {
        case idle       // Initial state, waiting for target
        case moving     // Moving towards target
        case retargeting // Searching for new target
        case attached   // Attached to cancer cell
    }
    
    // MARK: - State
    /// Current state of the ADC
    public var state: State = .idle
    
    // MARK: - Movement
    /// Movement progress (0 to 1)
    public var movementProgress: Float = 0
    
    /// Current velocity
    public var currentVelocity: SIMD3<Float>? = nil
    
    /// Speed of movement
    public var speed: Float = 2.0
    
    // MARK: - Target Information
    /// Target cancer cell ID
    public var targetCellID: Int? = nil
    
    /// ID of the target entity
    public var targetEntityID: UInt64? = nil
    
    /// Starting position in world space
    public var startWorldPosition: SIMD3<Float>? = nil
    
    /// Target position in world space
    public var targetWorldPosition: SIMD3<Float>? = nil
    
    /// Flag indicating if retargeting is needed
    public var needsRetarget: Bool = false
    
    // MARK: - Movement Parameters
    /// Speed factor for movement (random value between speedRange)
    public var speedFactor: Float? = nil
    
    /// Arc height factor for movement (random value between arcHeightRange)
    public var arcHeightFactor: Float? = nil
    
    // MARK: - Initialization
    /// Initialize ADC component and register system
    public init() {
    }
    
    /// Initialize ADC component with specified parameters
    public init(
        state: State = .idle,
        targetCellID: Int? = nil,
        targetEntityID: UInt64? = nil
    ) {
        self.state = state
        self.targetCellID = targetCellID
        self.targetEntityID = targetEntityID

    }
    
    enum CodingKeys: CodingKey {
        case state
        case movementProgress
        case currentVelocity
        case speed
        case targetCellID
        case targetEntityID
        case startWorldPosition
        case targetWorldPosition
        case needsRetarget
        case speedFactor
        case arcHeightFactor
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        state = try container.decode(State.self, forKey: .state)
        movementProgress = try container.decode(Float.self, forKey: .movementProgress)
        currentVelocity = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .currentVelocity)
        speed = try container.decode(Float.self, forKey: .speed)
        targetCellID = try container.decodeIfPresent(Int.self, forKey: .targetCellID)
        targetEntityID = try container.decodeIfPresent(UInt64.self, forKey: .targetEntityID)
        startWorldPosition = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .startWorldPosition)
        targetWorldPosition = try container.decodeIfPresent(SIMD3<Float>.self, forKey: .targetWorldPosition)
        needsRetarget = try container.decode(Bool.self, forKey: .needsRetarget)
        speedFactor = try container.decodeIfPresent(Float.self, forKey: .speedFactor)
        arcHeightFactor = try container.decodeIfPresent(Float.self, forKey: .arcHeightFactor)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(state, forKey: .state)
        try container.encode(movementProgress, forKey: .movementProgress)
        try container.encodeIfPresent(currentVelocity, forKey: .currentVelocity)
        try container.encode(speed, forKey: .speed)
        try container.encodeIfPresent(targetCellID, forKey: .targetCellID)
        try container.encodeIfPresent(targetEntityID, forKey: .targetEntityID)
        try container.encodeIfPresent(startWorldPosition, forKey: .startWorldPosition)
        try container.encodeIfPresent(targetWorldPosition, forKey: .targetWorldPosition)
        try container.encode(needsRetarget, forKey: .needsRetarget)
        try container.encodeIfPresent(speedFactor, forKey: .speedFactor)
        try container.encodeIfPresent(arcHeightFactor, forKey: .arcHeightFactor)
    }
}
