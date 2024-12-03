/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's window view.
*/

import SwiftUI
import RealityKit
import RealityKitContent

struct UIPortalView: View {
    /// The environment values to manage immersive spaces.
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(AppModel.self) private var appModel: AppModel

    /// A Boolean value that indicates whether the app shows the immersive space.
    @State private var immersive: Bool = false

    /// The root entity for other entities within the scene.
    private let root = Entity()

    /// A plane entity representing a portal.
    private let portalPlane = ModelEntity(
        mesh: .generatePlane(width: 1.0, height: 1.0),
        materials: [PortalMaterial()]
    )

    var body: some View {
        if appModel.phase == .intro {
            portalView
        } else {
            VStack {
                /// A button that launches the Attack Cancer immersive space.
                Button("Attack Cancer") {
                    Task {
                        await handleImmersiveSpaceTransition(to: "AttackCancerSpace")
                        await appModel.transitionToAttackCancer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()

                /// A button that dismisses the immersive space when someone taps it.
                Button("Exit") {
                    Task {
                        await dismissImmersiveSpace()
                        appModel.phase = .intro  // Return to intro
                    }
                }
                .padding()
            }
        }
    }

    /// A view that contains a portal and a button that opens the immersive space.
    var portalView: some View {
        ZStack {
            GeometryReader3D { geometry in
                RealityView { content in
                    await createPortal()
                    content.add(root)
                } update: { content in
                    // Resize the portal based on the size of the reality view content.
//                    let size = content.convert(geometry.size, from: .local, to: .scene)
                    updatePortalSize(width: 2.0, height: 1.0)
                }
                .frame(depth: 0.4)
            }
            .frame(depth: 0.4)

            VStack {
                /// A button that opens the Lab immersive space when someone taps it.
                Button("Enter The Lab") {
                    immersive = true
                    Task {
                        await handleImmersiveSpaceTransition(to: "LabSpace")
                    }
                }

                /// A button that opens the Intro immersive space when someone taps it.
                Button("Start The Intro") {
                    immersive = true
                    Task {
                        await handleIntroTransition(to: "IntroSpace")
                    }
                }
            }
        }
    }

    /// Sets up the portal and adds it to the `root`.
    @MainActor
    func createPortal() async {
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
    func updatePortalSize(width: Float, height: Float) {
        portalPlane.model?.mesh = .generatePlane(width: width, height: height, cornerRadius: 0.03)
    }

    // Add this function to handle immersive space transitions
    private func handleImmersiveSpaceTransition(to spaceID: String) async {
        if appModel.immersiveSpaceActive {
            await dismissImmersiveSpace()
            appModel.immersiveSpaceActive = false
            appModel.currentImmersiveSpaceID = nil
        }
        await openImmersiveSpace(id: spaceID)
        appModel.immersiveSpaceActive = true
        appModel.currentImmersiveSpaceID = spaceID
    }
    // Add this function to handle immersive space transitions
    private func handleIntroTransition(to spaceID: String) async {
        if appModel.immersiveSpaceActive {
            await dismissImmersiveSpace()
            appModel.immersiveSpaceActive = false
            appModel.currentImmersiveSpaceID = nil
        }
        await openImmersiveSpace(id: spaceID)
        appModel.immersiveSpaceActive = true
        appModel.currentImmersiveSpaceID = spaceID
    }
}
