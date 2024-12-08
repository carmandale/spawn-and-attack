import RealityKit

@MainActor
public struct CancerCellComponent: Component, Codable {
    public var cellID: Int? = nil
    public var hitCount: Int = 0
    public var isDestroyed: Bool = false
    public var currentScale: Float = 1.0
    public var isScaling: Bool = false  // Track if we're currently in a scaling animation
    public var targetScale: Float = 1.0  // The scale we're animating towards
    
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
    
    @MainActor
    public init(cellID: Int? = nil) {
        self.cellID = cellID
        // Generate random required hits between 7 and 18 for new cells
        self.requiredHits = Int.random(in: 7...18)
    }
    
    enum CodingKeys: CodingKey {
        case cellID
        case hitCount
        case isDestroyed
        case currentScale
        case isScaling
        case targetScale
        case requiredHits
    }
    
    nonisolated public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cellID = try container.decodeIfPresent(Int.self, forKey: .cellID)
        hitCount = try container.decode(Int.self, forKey: .hitCount)
        isDestroyed = try container.decode(Bool.self, forKey: .isDestroyed)
        currentScale = try container.decode(Float.self, forKey: .currentScale)
        isScaling = try container.decode(Bool.self, forKey: .isScaling)
        targetScale = try container.decode(Float.self, forKey: .targetScale)
        // Try to decode requiredHits, fall back to random value if not present
        if let existingHits = try? container.decode(Int.self, forKey: .requiredHits) {
            requiredHits = existingHits
        } else {
            requiredHits = Int.random(in: 7...18)
        }
    }
    
    nonisolated public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(cellID, forKey: .cellID)
        try container.encode(hitCount, forKey: .hitCount)
        try container.encode(isDestroyed, forKey: .isDestroyed)
        try container.encode(currentScale, forKey: .currentScale)
        try container.encode(isScaling, forKey: .isScaling)
        try container.encode(targetScale, forKey: .targetScale)
        try container.encode(requiredHits, forKey: .requiredHits)
    }
}
