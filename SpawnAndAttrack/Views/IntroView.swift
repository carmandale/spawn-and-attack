//
//  IntroView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 10/23/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct IntroView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.scenePhase) private var scenePhase
    
    /// The root entity for other entities within the scene.
    private let root = Entity()
    
    var body: some View {
        RealityView { content in
            // Create the root entity for our lab environment
            
            
            if let immersiveContentEntity = try? await Entity(named: "IntroEnvironment", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            }
            

        }
        .onChange(of: scenePhase, initial: true) {
            switch scenePhase {
            case .inactive, .background:
                appModel.introSpaceActive = false
            case .active:
                appModel.introSpaceActive = true
            @unknown default:
                appModel.introSpaceActive = false
            }
        }
    }
    
    
}
