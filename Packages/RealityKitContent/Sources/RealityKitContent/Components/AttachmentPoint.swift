import RealityKit

/// A component that marks an entity as an attachment point in Reality Composer Pro.
/// Runtime state is managed by `AttachmentStateComponent`.
public struct AttachmentComponent: Component, Codable {
    /// Whether this is a left or right attachment point
    public var isLeft: Bool = false

    public init() {}
    
    public init(isLeft: Bool) {
        self.isLeft = isLeft
    }
}
