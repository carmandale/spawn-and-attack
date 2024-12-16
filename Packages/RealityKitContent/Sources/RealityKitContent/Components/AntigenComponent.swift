import RealityKit

public struct AntigenComponent: Component, Codable {
    public var isRetracting: Bool = false
    public var retractionProgress: Float = 0  // 0 to 1
    public let targetY: Float = 2.5  // Fixed retraction distance
    
    public init() {}
}
