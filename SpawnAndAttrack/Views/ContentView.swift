import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        switch appModel.gamePhase {
        case .setup:
            LoadingView()
                .task {
                    await appModel.startLoading()
                    openWindow(id: AppModel.WindowState.debugNavigation.windowId)
                    // Open intro space when loading completes
                    await openImmersiveSpace(id: AppModel.SpaceState.intro.spaceId)
                    appModel.introSpaceActive = true
                }
        case .playing, .paused:
            // Main window shows current game phase
            VStack {
                Text("Let's Outdo Cancer")
                    .font(.largeTitle)
                    .padding()
            }
        case .completed:
            CompletedView()
        case .error:
            ErrorView()
        }
    }
}