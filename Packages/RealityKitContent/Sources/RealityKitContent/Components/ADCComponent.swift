import RealityKit

/// States that an ADC can be in during its lifecycle
public enum ADCState: String, Codable {
    case spawned
    case moving
    case attached
}

/// Component that tracks ADC state and movement
public struct ADCComponent: Component, Codable {
    /// Current state of the ADC
    public var state: ADCState = .spawned
    
    /// Target world position for movement
    public var targetWorldPosition: SIMD3<Float>?
    
    /// Start position for movement
    public var startWorldPosition: SIMD3<Float>?
    
    /// Movement progress (0 to 1)
    public var movementProgress: Float = 0
    
    public init() {}
}
