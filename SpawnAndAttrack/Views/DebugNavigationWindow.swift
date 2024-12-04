import SwiftUI

struct DebugNavigationWindow: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Debug Navigation")
                .font(.headline)

            ImmersiveSpaceButton(
                spaceID: .intro,
                isShowing: .init(
                    get: { appModel.introSpaceActive },
                    set: { appModel.introSpaceActive = $0 }
                ),
                label: "Go to Intro Space"
            )

            ImmersiveSpaceButton(
                spaceID: .lab,
                isShowing: .init(
                    get: { appModel.labSpaceActive },
                    set: { appModel.labSpaceActive = $0 }
                ),
                label: "Go to Lab Space"
            )

            ImmersiveSpaceButton(
                spaceID: .attack,
                isShowing: .init(
                    get: { appModel.attackSpaceActive },
                    set: { appModel.attackSpaceActive = $0 }
                ),
                label: "Go to Attack Space"
            )
        }
        .padding()
        .frame(maxWidth: 300)
    }
}