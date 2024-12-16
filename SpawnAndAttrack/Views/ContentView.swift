import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        switch appModel.currentPhase {
        case .loading:
            LoadingView()
                .task {
                    await appModel.startLoading()
                    await appModel.transitionToPhase(.intro)
                }
                .frame(width: 800, height: 300)
        case .intro:
            VStack {
                Text("Let's Outdo Cancer")
                    .font(.extraLargeTitle)
                    .fontWeight(.bold)
                    .padding()
            }
        case .playing, .completed, .lab, .building:
            EmptyView()
        case .error:
            ErrorView()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
