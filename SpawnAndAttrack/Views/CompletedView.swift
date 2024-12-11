import SwiftUI
import RealityKit
import RealityKitContent

struct CompletedView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var showConfetti = false
    @State private var animateStats = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Title with animation
            Text("Mission Accomplished!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .opacity(animateStats ? 1 : 0)
                .scaleEffect(animateStats ? 1 : 0.8)
                .animation(.spring(duration: 0.6), value: animateStats)
            
            // Stats Section with staggered animations
            VStack(alignment: .leading, spacing: 20) {
                Text("Your Impact")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .opacity(animateStats ? 1 : 0)
                    .offset(y: animateStats ? 0 : 20)
                    .animation(.spring(duration: 0.6).delay(0.3), value: animateStats)
                
                statsGrid
                    .opacity(animateStats ? 1 : 0)
                    .offset(y: animateStats ? 0 : 20)
                    .animation(.spring(duration: 0.6).delay(0.6), value: animateStats)
            }
            .padding()
            .glassBackgroundEffect()
            
            // Action Buttons with staggered animations
            VStack(spacing: 15) {
                Button("Start New Session") {
                    resetAndStartNew()
                    dismissWindow(id: AppModel.WindowID.gameCompleted)
                    Task {
                        await appModel.transitionToPhase(.intro)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                
                Button("Replay Attack Cancer") {
                    resetAndStartNew()
                    dismissWindow(id: AppModel.WindowID.gameCompleted)
                    Task {
                        await appModel.transitionToPhase(.playing)
                    }
                }
                .buttonStyle(.borderless)
                
                Button("Return to Lab") {
                    resetAndStartNew()
                    Task {
                        await appModel.transitionToPhase(.lab)
                    }
                }
                .buttonStyle(.borderless)
                
                Button("Return to Intro") {
                    resetAndStartNew()
                    Task {
                        await appModel.transitionToPhase(.intro)
                    }
                }
                .buttonStyle(.borderless)
            }
            .padding(.top)
            .opacity(animateStats ? 1 : 0)
            .offset(y: animateStats ? 0 : 20)
            .animation(.spring(duration: 0.6).delay(0.9), value: animateStats)
        }
        .padding(40)
        .frame(minWidth: 600, minHeight: 400)
        .glassBackgroundEffect()
        .onAppear {
            // Start animations when view appears
            withAnimation {
                showConfetti = true
                animateStats = true
            }
        }
        .onDisappear {
            // Reset animations when view disappears
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
    
    private var statsGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 30, verticalSpacing: 15) {
            // Total Cells Destroyed
            GridRow {
                Label("Cancer Cells Destroyed", systemImage: "target")
                    .foregroundStyle(.secondary)
                Text("\(appModel.gameState.cellsDestroyed)")
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            
            // Total ADCs Deployed
            GridRow {
                Label("ADCs Deployed", systemImage: "arrow.up.forward")
                    .foregroundStyle(.secondary)
                Text("\(appModel.gameState.totalADCsDeployed)")
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            
            // Total Hits
            GridRow {
                Label("Successful Hits", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
                Text("\(appModel.gameState.totalHits)")
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            
            // Score
            GridRow {
                Label("Final Score", systemImage: "star.fill")
                    .foregroundStyle(.secondary)
                Text("\(appModel.gameState.score)")
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
        }
    }
    
    private func resetAndStartNew() {
        // Reset animations
        showConfetti = false
        animateStats = false
        
        // Reset game state and transition to playing phase
        appModel.gameState.resetGameState()
    }
}
