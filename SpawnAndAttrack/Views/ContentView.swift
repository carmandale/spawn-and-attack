import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        switch appModel.gamePhase {
        case .setup:
            LoadingView()
                .task {
                    await appModel.startLoading()
                    openWindow(id: AppModel.WindowState.debugNavigation.windowId)
                    appModel.gamePhase = .playing
                }
        case .playing, .paused:
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