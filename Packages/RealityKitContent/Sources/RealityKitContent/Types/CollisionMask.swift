/*
Abstract:
Defines collision categories for ADC targeting game physics.
*/

import RealityKit

public struct CollisionMask: OptionSet, Sendable, Codable {
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public static let none: CollisionMask = []
    public static let adc = CollisionMask(rawValue: 1 << 0)
    public static let cancerCell = CollisionMask(rawValue: 1 << 1)
    public static let attachmentPoint = CollisionMask(rawValue: 1 << 2)
    public static let all: CollisionMask = [.adc, .cancerCell, .attachmentPoint]
}
