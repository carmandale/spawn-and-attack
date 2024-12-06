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
            // if let immersiveContentEntity = try? await Entity(named: "BloodCellEnvironment", in: realityKitContentBundle) {
            //     content.add(immersiveContentEntity)
            // }
            
           if let bloodCellEnvironmentEntity = await appModel.assetLoadingManager.instantiateEntity("build_adc_environment") {
               content.add(bloodCellEnvironmentEntity)
           } else {
               print("Failed to load build_adc_environment from asset manager")
           }
        } update: { content in
            
        }
        .installGestures()
    }
}
