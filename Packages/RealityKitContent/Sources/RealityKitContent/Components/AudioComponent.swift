import RealityKit

// Ensure you register this component in your app's delegate using:
// audioComponent.registerComponent()
public struct AudioComponent: Component, Codable {
    var droneSound: String = ""
    var attachSound: String = ""

    public init() {
    }
}
