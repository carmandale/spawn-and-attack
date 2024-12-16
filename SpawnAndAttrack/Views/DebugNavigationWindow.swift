import SwiftUI

struct DebugNavigationWindow: View {
    @Environment(AppModel.self) private var appModel
    @State private var numberOfCancerCells: Double = 15  // Default value to match GameState

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 30) {
                // Title
                Text("Debug Navigation")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Slider Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Max Cancer Cells")
                        .font(.headline)

                    HStack {
                        Text("1")
                            .font(.caption)

                        Slider(value: $numberOfCancerCells, in: 1...20, step: 1) {
                            Text("Number of Cancer Cells")
                        }

                        Text("20")
                            .font(.caption)
                    }

                    Text("Current Value: \(Int(numberOfCancerCells))")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .shadow(radius: 5)
                )
                .onAppear {
                    // Synchronize initial value with GameState
                    numberOfCancerCells = Double(appModel.gameState.maxCancerCells)
                }
                .onChange(of: numberOfCancerCells) { _, newValue in
                    appModel.gameState.maxCancerCells = Int(newValue)
                }

                // Navigation Buttons
                VStack(spacing: 15) {
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
                .padding()
            }
            .padding(20)
        }
    }
}


#Preview(windowStyle: .automatic) {
    DebugNavigationWindow()
        .environment(AppModel())
}
