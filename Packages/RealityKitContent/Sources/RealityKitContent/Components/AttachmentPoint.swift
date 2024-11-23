import RealityKit

public struct AttachmentPoint: Component, Codable {
    public var isLeft: Bool = false
    public var isOccupied: Bool = false
    public var pendingStateChange: Bool = false

    public init() {
    }
    
    public init(isLeft: Bool) {
        self.isLeft = isLeft
    }
}
