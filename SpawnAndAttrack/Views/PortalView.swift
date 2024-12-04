//
//  Portal.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/4/24.
//
import SwiftUI
import RealityKit
import RealityKitContent

struct PortalView: View {
        @Environment(AppModel.self) private var appModel
        @Environment(\.scenePhase) private var scenePhase
        
        /// The root entity for other entities within the scene.
        private let root = Entity()
        
        /// A plane entity representing a portal.
        private let portalPlane = ModelEntity(
            mesh: .generatePlane(width: 1.0, height: 1.0),
            materials: [PortalMaterial()]
        )
        
        var body: some View {
            ZStack {
                GeometryReader3D { geometry in
                    RealityView { content in
                        
                        // Add portal
                        await createPortal()
                        content.add(root)
                    } update: { content in
                        // Resize the scene based on the size of the reality view content.
                        let size = content.convert(geometry.size, from: .local, to: .scene)
                        updatePortalSize(width: size.x, height: size.y)
                    }
                    .frame(depth: 0.4)
                }
                .frame(depth: 0.4)
                
                // Only show controls when game is playing
                if appModel.gamePhase == .playing {
                    VStack {
                        ImmersiveSpaceButton(
                            label: "Enter The Lab",
                            spaceID: "LabSpace",
                            isOpen: appModel.labSpaceActive
                        )
                    }
                }
            }
            .onChange(of: scenePhase, initial: true) {
                switch scenePhase {
                case .inactive, .background:
                    appModel.introSpaceActive = false
                case .active:
                    appModel.introSpaceActive = true
                @unknown default:
                    appModel.introSpaceActive = false
                }
            }
        }
        
        /// Sets up the portal and adds it to the `root`.
        @MainActor
        private func createPortal() async {
            // Create the entity that stores the content within the portal.
            let world = Entity()
            
            // Shrink the portal world and update the position
            // to make it fit into the portal view.
            world.scale *= 0.5
            world.position.y -= 0.5
            world.position.z -= 0.5
            
            // Allow the entity to be visible only through a portal.
            world.components.set(WorldComponent())
            
            // Create the lab environment and add it to the world.
            if let labEntity = try? await Entity(named: "LabEnvironment", in: realityKitContentBundle) {
                world.addChild(labEntity)
            } else {
                print("Failed to load LabEnvironment from assets.")
            }
            
            // Set up the portal to show the content in the `world`.
            portalPlane.components.set(PortalComponent(target: world))
            root.addChild(portalPlane)
            root.addChild(world)
        }
        
        /// Configures the portal mesh's width and height.
        private func updatePortalSize(width: Float, height: Float) {
            portalPlane.model?.mesh = .generatePlane(width: width, height: height, cornerRadius: 0.03)
        }
    }
