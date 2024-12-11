import SwiftUI
import RealityKit

@MainActor
final class PortalManager {
    /// Sets up the portal and adds it to the `root.`
    static func createPortal(appModel: AppModel) async -> Entity {
        let root = Entity()
        let portalPlane = ModelEntity(
            mesh: .generatePlane(width: 1.0, height: 2.0),
            materials: [PortalMaterial()]
        )
        
        // Create the entity that stores the content within the portal.
        let world = Entity()

        // Shrink the portal world and update the position
        // to make it fit into the portal view.
        world.scale *= 0.35
        world.position.y -= 0.5
        world.position.z -= 1.5

        // Allow the entity to be visible only through a portal.
        world.components.set(WorldComponent())
        
        // Create the box environment and add it to the root.
        guard let labEnvironment = await appModel.assetLoadingManager.instantiateEntity("lab_environment") else {
            print("Failed to load LabEnvironment from asset manager")
            return root
        }
        
        world.addChild(labEnvironment)

        // Set up the portal to show the content in the `world`.
        portalPlane.components.set(PortalComponent(target: world))
        root.addChild(portalPlane)
        root.addChild(world)

        return root 
    }
}
