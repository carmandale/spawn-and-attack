import SwiftUI
import RealityKitContent

struct DebugNavigationWindow: View {
    @Environment(AppModel.self) private var appModel
    @State private var numberOfCancerCells: Double = 15  // Default value to match GameState
    @State private var testParams = CancerCellParameters()  // Test our Observable class
    @State private var testValue: Int = 0  // Local state for test value

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

                // Test Parameters Section
                VStack(alignment: .leading) {
                    Text("Test Parameters")
                        .font(.headline)
                    Text("Value: \(testValue)")
                    Button("Increment") {
                        testValue += 1
                        testParams.testValue = testValue
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.1))
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
