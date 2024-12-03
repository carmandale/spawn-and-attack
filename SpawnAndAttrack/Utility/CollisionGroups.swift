import RealityKit

extension CollisionGroup {
    static let cancerCell = CollisionGroup(rawValue: 1 << 0)
    static let adc = CollisionGroup(rawValue: 1 << 1)
    // From reference project: Used to exclude objects from earth's gravity when using custom gravity
    static let actualEarthGravity = CollisionGroup(rawValue: 100 << 0)
}