import RealityKit
import Foundation

/// Represents the state of an ADC entity
/// Following SwiftSplash pattern of separating state from behavior
@MainActor
public struct ADCStateComponent: Component, Codable {
    /// Current state of the ADC
    public enum State: UInt8, Codable {
        case spawning
        case moving
        case attached
        case destroying
    }
    
    /// Current state of this ADC
    public private(set) var state: State = .spawning
    
    /// The attachment point this ADC is connected to (if any)
    public private(set) var attachedTo: Entity?
    
    /// The path this ADC is following
    public private(set) var pathKeyframes: [Transform]?
    
    /// Current progress along the path (0-1)
    public private(set) var pathProgress: Float = 0
    
    /// Elapsed time in current state
    public private(set) var elapsedTime: TimeInterval = 0
    
    /// Last update timestamp for precise timing
    public private(set) var lastUpdateTime: TimeInterval = 0
    
    /// Animation state for visual feedback
    public private(set) var visualState: VisualState = .normal
    
    /// Visual state of the ADC for animation
    public enum VisualState: UInt8, Codable {
        case normal
        case highlighted
        case attaching
        case destroying
    }
    
    public init() {}
    
    /// Updates the state with proper timing
    @inline(__always)
    public mutating func updateState(_ newState: State) {
        state = newState
        elapsedTime = 0
        lastUpdateTime = CACurrentMediaTime()
    }
    
    /// Updates the path with validation
    @inline(__always)
    public mutating func updatePath(_ keyframes: [Transform]?) {
        pathKeyframes = keyframes
        pathProgress = 0
    }
    
    /// Updates progress with bounds checking
    @inline(__always)
    public mutating func updateProgress(_ progress: Float) {
        pathProgress = max(0, min(1, progress))
    }
    
    /// Updates attachment with proper cleanup
    @inline(__always)
    public mutating func updateAttachment(_ entity: Entity?) {
        if attachedTo != entity {
            // Clean up old attachment if needed
            attachedTo = entity
            if entity != nil {
                visualState = .attaching
            }
        }
    }
    
    /// Updates timing with proper delta
    @inline(__always)
    public mutating func updateTiming(_ deltaTime: TimeInterval) {
        elapsedTime += deltaTime
        lastUpdateTime = CACurrentMediaTime()
    }
}

/// Defines the behavior configuration of an ADC entity
/// Following BOTAnist pattern of optimized component access
@MainActor
public struct ADCBehaviorComponent: Component, Codable {
    /// Movement speed in meters per second
    public var speed: Float = 2.0
    
    /// Maximum lifetime in seconds (0 = infinite)
    public var maxLifetime: TimeInterval = 0
    
    /// Whether this ADC can attach to cancer cells
    public var canAttach: Bool = true
    
    /// Sound effect configuration
    public struct SoundEffects: Codable {
        public var droneSound: String = "Drones_01.wav"
        public var attachSound: String = "Sonic_Pulse_Hit_01.wav"
        public var volume: Float = 1.0
        
        public init() {}
    }
    
    /// Sound effect settings
    public var soundEffects = SoundEffects()
    
    /// Animation configuration for visual feedback
    public struct AnimationConfig: Codable {
        /// Duration of attach animation
        public var attachDuration: TimeInterval = 0.3
        /// Duration of destroy animation
        public var destroyDuration: TimeInterval = 0.5
        /// Scale factor for highlight effect
        public var highlightScale: Float = 1.2
        
        public init() {}
    }
    
    /// Animation settings
    public var animation = AnimationConfig()
    
    public init() {}
}

/// Component for pooling and lifecycle management
/// Following Spaceship pattern of entity management
@MainActor
public struct ADCPoolComponent: Component {
    /// Whether this entity is currently active in the pool
    public var isActive: Bool = false
    
    /// Time when this entity was last recycled
    public var lastRecycleTime: TimeInterval = 0
    
    /// Number of times this entity has been reused
    public var reuseCount: Int = 0
    
    public init() {}
}
