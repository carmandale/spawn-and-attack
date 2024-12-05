import RealityKit

@MainActor
public struct CancerCellComponent: Component, Codable {
    public var cellID: Int? = nil
    public var hitCount: Int = 0
    public var isDestroyed: Bool = false
    public var currentScale: Float = 1.0
    public var isScaling: Bool = false
    public var targetScale: Float = 1.0
    
    // Each cell gets its own required hits value
    public var requiredHits: Int = 3
    
    // Class-level default for UI/display purposes
    public static let defaultRequiredHits = 18
    
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
        self.requiredHits = Int.random(in: 5...18)
        print("\n=== Cancer Cell Component Creation ===")
        print("Created cell \(cellID ?? -1) with requiredHits: \(requiredHits)")
    }
}
