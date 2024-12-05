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
    
    /// The root entity for other entities within the scene.
    private let root = Entity()
    
    var body: some View {
        RealityView { content in
            if let immersiveContentEntity = try? await Entity(named: "IntroEnvironment", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            }
        }
    }
}
