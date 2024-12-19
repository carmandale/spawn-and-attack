import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        switch appModel.currentPhase {
        case .loading:
            LoadingView()
                .task {
                    await appModel.startLoading()
                }
                .frame(width: 800, height: 300)
        case .intro, .playing, .completed, .lab, .building, .error:
            EmptyView()  // No content needed for other phases as they use different windows
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
