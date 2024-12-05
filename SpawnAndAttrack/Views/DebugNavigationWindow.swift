import SwiftUI

struct DebugNavigationWindow: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Debug Navigation")
                .font(.headline)

            Button("Go to Intro Space") {
                appModel.startIntroPhase()
            }

            Button("Go to Lab Space") {
                appModel.startLabPhase()
            }

            Button("Go to Attack Space") {
                appModel.startAttackPhase()
            }
        }
        .padding(20)
        
    }
}
