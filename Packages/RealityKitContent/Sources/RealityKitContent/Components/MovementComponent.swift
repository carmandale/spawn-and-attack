import RealityKit
import Foundation

/// A component that defines movement parameters for an entity
@MainActor
public struct MovementComponent: Component, Codable {
    /// The duration of the movement effect
    public var time: Double = 0
    
    /// The speed at which the entity moves over time
    public var speed: Double = 1.0
    
    /// The axis that the object rotates around
    public var axis: [Float] = [0, 1, 0]
    
    /// Initialize the movement component with default values
    public init() {}
    
    /// Initialize the movement component with specified parameters
    /// - Parameters:
    ///   - speed: Speed of movement over time
    ///   - axis: Axis of rotation as an array of floats [x, y, z]
    public init(speed: Double = 1.0, axis: [Float] = [0, 1, 0]) {
        self.speed = speed
        self.axis = axis
    }
}
