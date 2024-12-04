import SwiftUI
import RealityKit
import RealityKitContent

struct CompletedView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
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
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                
                Button("Replay Attack Cancer") {
                    Task {
                        if appModel.immersiveSpaceActive {
                            await dismissImmersiveSpace()
                            appModel.introSpaceActive = false
                            appModel.labSpaceActive = false
                            appModel.attackSpaceActive = false
                        }
                        appModel.gamePhase = .playing
                        await openImmersiveSpace(id: "AttackSpace")
                        appModel.attackSpaceActive = true
                    }
                }
                .buttonStyle(.borderless)
                
                Button("Return to Lab") {
                    Task {
                        if appModel.immersiveSpaceActive {
                            await dismissImmersiveSpace()
                            appModel.introSpaceActive = false
                            appModel.labSpaceActive = false
                            appModel.attackSpaceActive = false
                        }
                        await openImmersiveSpace(id: "LabSpace")
                        appModel.labSpaceActive = true
                    }
                }
                .buttonStyle(.borderless)
                
                Button("Return to Intro") {
                    Task {
                        if appModel.immersiveSpaceActive {
                            await dismissImmersiveSpace()
                            appModel.introSpaceActive = false
                            appModel.labSpaceActive = false
                            appModel.attackSpaceActive = false
                        }
                        await openImmersiveSpace(id: "IntroSpace")
                        appModel.introSpaceActive = true
                    }
                }
                .buttonStyle(.borderless)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: 500)
    }
    
    private var statsGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 30, verticalSpacing: 15) {
            // Total Cells Destroyed
            GridRow {
                Label("Cancer Cells Destroyed", systemImage: "target")
                    .foregroundStyle(.secondary)
                Text("\(appModel.totalCellsDestroyed)")
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
            
            // Hit Count
            GridRow {
                Label("Successful Hits", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
                Text("\(appModel.hitCount)")
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
        }
    }
    
    private func resetAndStartNew() {
        // Reset all game stats
        appModel.resetHitCounts()
        
        // Reset game state
        appModel.gamePhase = .setup
        
        // Reset space states
        appModel.introSpaceActive = false
        appModel.labSpaceActive = false
        appModel.attackSpaceActive = false
        appModel.isShowingADCBuilder = false
        appModel.isShowingADCVolumetric = false
        appModel.isShowingDebugNavigation = false
    }
}
