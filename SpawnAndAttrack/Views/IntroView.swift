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
            // do {
            //     let immersiveContentEntity = try await Entity(named: "AttackCancerEnvironment", in: realityKitContentBundle)
            //     content.add(immersiveContentEntity)
            //     print("Successfully loaded AttackCancerEnvironment")
                
            //     let cancerCellEntity = try await Entity(named: "CancerCell-spawn", in: realityKitContentBundle)
            //     print("Successfully loaded CancerCell-spawn")

            //     let adcEntity = try await Entity(named: "ADC-spawn", in: realityKitContentBundle)
            //     print("Successfully loaded ADC-spawn")

            //     content.add(cancerCellEntity)
            //     content.add(adcEntity)
                
            // } catch {
            //     print("Failed to load AttackCancerEnvironment: \(error)")
            // }

            

//            Load Intro Environment from pre-loaded assets.
            if let introEnvironmentEntity = await appModel.assetLoadingManager.instantiateEntity("intro_environment") {
                content.add(introEnvironmentEntity)
            } else {
                print("Failed to load IntroEnvironment from asset manager")
            }
        }
    }
}
