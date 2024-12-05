import SwiftUI
import RealityKit
import RealityKitContent

struct CompletedView: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        VStack(spacing: 30) {
            // Title
            Text("Mission Accomplished!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // Stats Section
            VStack(alignment: .leading, spacing: 20) {
                Text("Your Impact")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                statsGrid
            }
            .padding()
            .glassBackgroundEffect()
            
            // Action Buttons
            VStack(spacing: 15) {
                Button("Start New Session") {
                    resetAndStartNew()
                    appModel.startIntroPhase()
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                
                Button("Replay Attack Cancer") {
                    resetAndStartNew()
                    appModel.startAttackPhase()
                }
                .buttonStyle(.borderless)
                
                Button("Return to Lab") {
                    resetAndStartNew()
                    appModel.startLabPhase()
                }
                .buttonStyle(.borderless)
                
                Button("Return to Intro") {
                    resetAndStartNew()
                    appModel.startIntroPhase()
                }
                .buttonStyle(.borderless)
            }
            .padding(.top)
        }
        .padding(40)
        .frame(minWidth: 600, minHeight: 400)
        .glassBackgroundEffect()
    }
    
    private var statsGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 30, verticalSpacing: 15) {
            // Total Cells Destroyed
            GridRow {
                Label("Cancer Cells Destroyed", systemImage: "target")
                    .foregroundStyle(.secondary)
                Text("\(appModel.cellsDestroyed)")
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            
            // Total ADCs Deployed
            GridRow {
                Label("ADCs Deployed", systemImage: "arrow.up.forward")
                    .foregroundStyle(.secondary)
                Text("\(appModel.totalADCsDeployed)")
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            
            // Total Hits
            GridRow {
                Label("Successful Hits", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
                Text("\(appModel.totalHits)")
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
        }
    }
    
    private func resetAndStartNew() {
        // Reset game state but don't reload assets
        appModel.resetGameState()
    }
}
