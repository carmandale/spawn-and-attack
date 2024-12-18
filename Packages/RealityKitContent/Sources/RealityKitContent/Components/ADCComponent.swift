import RealityKit

/// Component that tracks ADC state and movement
public struct ADCComponent: Component, Codable {
    /// Current state of the ADC
    public enum State: String, Codable {
        case idle
        case moving
        case attached
    }
    
    /// Current state of the ADC
    public var state: State = .idle
    
    /// Movement progress (0 to 1)
    public var movementProgress: Float = 0
    
    /// Start position for movement
    public var startWorldPosition: SIMD3<Float>?
    
    /// Target world position for movement
    public var targetWorldPosition: SIMD3<Float>?
    
    /// Target cell ID
    public var targetCellID: Int?
    
    /// ID of the target attachment point entity
    public var targetEntityID: UInt64?
    
    /// Target attachment point ID
    public var targetAttachmentPointID: String?
    
    /// Store spin speed for consistent rotation
    public var spinSpeed: Float?
    
    public init() {}
}
