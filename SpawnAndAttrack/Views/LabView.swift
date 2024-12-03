//
//  LabView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 10/23/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

/// A RealityView that creates an immersive lab environment with spatial audio and IBL lighting
struct LabView: View {
    @Environment(AppModel.self) private var appModel: AppModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        RealityView { content in
            // Create the root entity for our lab environment
            let rootEntity = Entity()
            
            do {
                // Set up IBL lighting
                try await setupLighting(on: rootEntity)
                
                // Load Lab Environment from pre-loaded assets
                if let labEnvironmentScene = await appModel.assetLoadingManager.instantiateEntity("lab_environment") {
                    rootEntity.addChild(labEnvironmentScene)
                } else {
                    print("Failed to load LabEnvironment from asset manager")
                }
                
                // Temporarily comment out equipment loading to test
                let equipmentScene = try await appModel.assetLoadingManager.loadPopulatedLabScene()
                rootEntity.addChild(equipmentScene)
                
                // Add the root entity to the content
                content.add(rootEntity)
                
            } catch {
                print("Error setting up lab environment: \(error.localizedDescription)")
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                appModel.immersiveSpaceActive = false
                appModel.currentImmersiveSpaceID = nil
            }
        }
        .onAppear {
            appModel.phase = .lab
        }
        .onDisappear {
            appModel.phase = .intro
        }
    }
    
    /// Sets up image-based lighting for the lab environment
    private func setupLighting(on root: Entity) async throws {
        // Load the EXR file for IBL
        guard let iblURL = Bundle.main.url(forResource: "metro_noord_2k", withExtension: "exr") else {
            fatalError("Failed to load the Image-Based Lighting file.")
        }
        
        // Create environment resource from the EXR file
        let iblEnvironment = try await EnvironmentResource(fromImage: iblURL)
        
        // Create entity for IBL
        let iblEntity = Entity()
        
        // Create and configure IBL component
        var iblComponent = ImageBasedLightComponent(source: .single(iblEnvironment), intensityExponent: 0.0)
        iblComponent.inheritsRotation = true
        
        // Add IBL component to the entity
        iblEntity.components.set(iblComponent)
        
        // Make the root entity receive the IBL
        root.components.set(ImageBasedLightReceiverComponent(imageBasedLight: iblEntity))
    }
}
