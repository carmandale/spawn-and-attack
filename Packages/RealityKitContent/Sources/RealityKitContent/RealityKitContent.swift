import Foundation
import RealityKit

/// Bundle for the RealityKitContent project
public let realityKitContentBundle = Bundle.module

/// Configure RealityKit content
@MainActor
public func configureRealityKitContent() {
    // Register components first
    AttachmentComponent.registerComponent()
    AttachmentStateComponent.registerComponent()
    
    // Then register systems
    AttachmentSystem.registerSystem()
}
