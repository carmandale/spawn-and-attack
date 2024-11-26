import RealityKit
import SwiftUI

@MainActor
public class UIAttachmentSystem: System {
    /// Query for entities with both CancerCell and UIAttachment components
    static let query = EntityQuery(where: .has(CancerCellComponent.self) && .has(UIAttachmentComponent.self))
    
    public required init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let uiAttachment = entity.components[UIAttachmentComponent.self],
                  let cancerCell = entity.components[CancerCellComponent.self] else { continue }
            
            // The system doesn't need to do much here since:
            // 1. The attachment position is handled by RealityKit (parent-child relationship)
            // 2. The hit count is managed in CancerCellComponent
            // 3. The UI updates automatically through SwiftUI bindings
            
            // We could add additional logic here if needed, such as:
            // - Updating attachment visibility based on distance/angle to camera
            // - Animating the attachment position/rotation
            // - Handling attachment lifecycle (creation/destruction)
        }
    }
}
