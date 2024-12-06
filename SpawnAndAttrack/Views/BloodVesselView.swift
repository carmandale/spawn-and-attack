//
//  BloodVesselView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/5/24.
//


import SwiftUI
import RealityKit
import RealityKitContent

struct BloodVesselView: View {
    @Environment(AppModel.self) private var appModel
    
    /// The root entity for other entities within the scene.
    private let root = Entity()
    
    var body: some View {
        RealityView { content in
            if let immersiveContentEntity = try? await Entity(named: "BloodVesselScene", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            }
        }
    }
}
