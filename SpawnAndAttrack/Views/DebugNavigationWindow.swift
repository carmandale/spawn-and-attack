import SwiftUI

struct DebugNavigationWindow: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Debug Navigation")
                .font(.headline)

            Button("Go to Intro Space") {
                Task {
                    await appModel.transitionToPhase(.intro)
                }
            }

            Button("Go to Lab Space") {
                Task {
                    await appModel.transitionToPhase(.lab)
                }
            }

            Button("Go to Building Space") {
                Task {
                    await appModel.transitionToPhase(.building)
                }
            }

            Button("Go to Attack Space") {
                Task {
                    await appModel.transitionToPhase(.playing)
                }
            }
        }
        .padding(20)
        
    }
}
