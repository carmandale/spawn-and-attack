import RealityKit

public enum ADCState: String, Codable {
    case spawned
    case moving
    case attached
}

public struct ADCComponent: Component, Codable {
    public var state: ADCState
    
    public init() {
        self.state = .spawned
    }
}
