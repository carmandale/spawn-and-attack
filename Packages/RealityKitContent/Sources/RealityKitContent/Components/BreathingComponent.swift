import RealityKit

@MainActor
public struct BreathingComponent: Component, Codable {
    /// Current breathing phase (0 to 2π)
    public var phase: Float = 0.0
    
    /// Duration of one complete breath cycle in seconds
    public var cycleDuration: Float
    
    /// Maximum scale change during breathing
    public var intensity: Float
    
    /// Base scale to breathe around
    public var baseScale: Float = 1.0
    
    public init(
        cycleDuration: Float = Float.random(in: 3.0...5.0),  // Random duration per cell
        intensity: Float = Float.random(in: 0.03...0.07)     // Random intensity per cell
    ) {
        self.cycleDuration = cycleDuration
        self.intensity = intensity
    }
} 