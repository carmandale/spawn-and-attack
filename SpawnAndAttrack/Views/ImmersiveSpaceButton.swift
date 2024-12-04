import SwiftUI

struct ImmersiveSpaceButton: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    let spaceID: AppModel.SpaceState
    @Binding var isShowing: Bool
    let label: String

    var body: some View {
        Button(action: {
            Task {
                if appModel.immersiveSpaceActive {
                    await dismissImmersiveSpace()
                }
                if !isShowing {
                    await openImmersiveSpace(id: spaceID.spaceId)
                }
            }
        }, label: {
            Text(isShowing ? "Close \(label) Space" : "Open \(label) Space")
        })
        .buttonStyle(.bordered)
    }
}
