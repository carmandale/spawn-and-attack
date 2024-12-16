import RealityKit

public struct CancerCellComponent: Component, Codable {
    public var cellID: Int? = nil
    public var hitCount: Int = 0
    public var isDestroyed: Bool = false
    public var currentScale: Float = 1.0
    public var isScaling: Bool = false  // Track if we're currently in a scaling animation
    public var targetScale: Float = 1.0  // The scale we're animating towards
    public var wasJustHit: Bool = false  // Track when a new hit occurs
    public var isEmittingParticles: Bool = false  // Track particle emitter state
    
    /// The number of hits required to destroy this specific cancer cell
    public var requiredHits: Int = 18  // Default to 18 for backward compatibility
    
    // Scale thresholds for different hit counts
    public static let scaleThresholds: [(hits: Int, scale: Float)] = [
        (1, 0.9),   // First hit
        (3, 0.8),   // Third hit
        (6, 0.7),   // Sixth hit
        (9, 0.6),   // Ninth hit
        (12, 0.5),  // Twelfth hit
        (15, 0.4)   // Fifteenth hit
    ]
    
    public init(cellID: Int? = nil) {
        self.cellID = cellID
        // Generate random required hits between 5 and 18 for new cells
        self.requiredHits = Int.random(in: 5...18)
        print("✨ Initializing CancerCellComponent with isEmittingParticles=\(isEmittingParticles)")
    }
}
