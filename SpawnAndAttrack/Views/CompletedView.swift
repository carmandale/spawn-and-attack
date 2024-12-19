import SwiftUI
import RealityKit
import RealityKitContent

// TODO improve the look of this view and confirm when it should appear and how it appears

struct CompletedView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var showConfetti = false
    @State private var animateStats = false
    
    // Get stats from AttackCancerViewModel
    private var stats: (destroyed: Int, deployed: Int, score: Int) {
        let gameState = appModel.gameState
        return (
            destroyed: gameState.cellsDestroyed,
            deployed: gameState.totalADCsDeployed,
            score: gameState.score
        )
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.2), .purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Title with animation
                Text("🎉 Mission Accomplished! 🎉")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(animateStats ? 1 : 0)
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .animation(.interpolatingSpring(stiffness: 100, damping: 8), value: animateStats)
                
                // Stats Section with staggered animations
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Impact")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .opacity(animateStats ? 1 : 0)
                        .offset(y: animateStats ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateStats)
                    
                    statsGrid
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .shadow(radius: 5)
                        )
                        .padding()
                        .opacity(animateStats ? 1 : 0)
                        .offset(y: animateStats ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: animateStats)
                }
                
                // Action Buttons with staggered animations
                VStack(spacing: 15) {
                    ActionButton(title: "Start New Session", icon: "arrow.triangle.2.circlepath") {
                        resetAndStartNew()
                        Task {
                            await appModel.transitionToPhase(.intro)
                        }
                    }
                    
                    ActionButton(title: "Replay Attack Cancer", icon: "arrow.clockwise") {
                        resetAndStartNew()
                        Task {
                            await appModel.transitionToPhase(.playing)
                        }
                    }
                    
                    ActionButton(title: "Return to Lab", icon: "building.2.crop.circle") {
                        resetAndStartNew()
                        Task {
                            await appModel.transitionToPhase(.lab)
                        }
                    }
                    
                    ActionButton(title: "Return to Intro", icon: "house") {
                        resetAndStartNew()
                        Task {
                            await appModel.transitionToPhase(.intro)
                        }
                    }
                }
                .opacity(animateStats ? 1 : 0)
                .offset(y: animateStats ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.9), value: animateStats)
            }
            .padding(40)
            .frame(maxWidth: 600, maxHeight: 400)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .shadow(radius: 10)
            )
            .onAppear {
                withAnimation {
                    showConfetti = true
                    animateStats = true
                }
            }
            .onDisappear {
                showConfetti = false
                animateStats = false
            }
            .onChange(of: appModel.currentPhase) { oldPhase, newPhase in
                if newPhase == .completed {
                    withAnimation {
                        showConfetti = true
                        animateStats = true
                    }
                }
            }
        }
    }
    
    private var statsGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 30, verticalSpacing: 15) {
            // Total Cells Destroyed
            GridRow {
                Label("Cancer Cells Destroyed", systemImage: "target")
                    .foregroundStyle(.secondary)
                Text("\(stats.destroyed)")
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            
            // Total ADCs Deployed
            GridRow {
                Label("ADCs Deployed", systemImage: "arrow.up.forward")
                    .foregroundStyle(.secondary)
                Text("\(stats.deployed)")
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            
            // Score
            GridRow {
                Label("Final Score", systemImage: "star.fill")
                    .foregroundStyle(.secondary)
                Text("\(stats.score)")
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
        }
    }
    
    private func resetAndStartNew() {
        showConfetti = false
        animateStats = false
        appModel.gameState.resetGameState()
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
            .foregroundColor(.white)
            .shadow(radius: 5)
        }
    }
}
