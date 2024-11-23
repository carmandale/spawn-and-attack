/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A component that holds state values for attachment points.
*/

import RealityKit
import Foundation

/// A component to hold internal state values. The project separates these values into a
/// separate component from `AttachmentComponent` so that Reality Composer Pro doesn't display these values.
@MainActor
public struct AttachmentStateComponent: Component {
    /// Whether this attachment point is currently occupied
    public var isOccupied = false
    
    /// The last time this attachment point was interacted with
    public var lastInteractionTime: TimeInterval = 0
    
    /// The entity currently connected to this attachment point
    public var connectedEntity: Entity?
    
    /// The position of the attachment point in world space
    public var attachmentPoint: SIMD3<Float>?
    
    /// Whether this is a left or right attachment point
    public var isLeft: Bool = false
    
    /// The time when the current connection was established
    public var connectionStartTime: TimeInterval = 0
    
    /// The duration this attachment point has been occupied
    public var occupationDuration: TimeInterval {
        guard isOccupied else { return 0 }
        return Date().timeIntervalSince1970 - connectionStartTime
    }
    
    public init() {}
    
    /// Updates the state when an entity connects to this attachment point
    public mutating func connect(to entity: Entity, at position: SIMD3<Float>, isLeft: Bool) {
        self.isOccupied = true
        self.connectedEntity = entity
        self.attachmentPoint = position
        self.isLeft = isLeft
        self.lastInteractionTime = Date().timeIntervalSince1970
        self.connectionStartTime = self.lastInteractionTime
    }
    
    /// Resets the attachment point state when disconnected
    public mutating func disconnect() {
        self.isOccupied = false
        self.connectedEntity = nil
        self.lastInteractionTime = Date().timeIntervalSince1970
    }
}
