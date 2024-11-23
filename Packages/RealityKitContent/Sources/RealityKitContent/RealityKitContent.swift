import Foundation
import RealityKit

/// Bundle for the RealityKitContent project
public let realityKitContentBundle = Bundle.module

/// Configure RealityKit content
public func configureRealityKitContent() {
    AttachmentPoint.registerComponent()
}
