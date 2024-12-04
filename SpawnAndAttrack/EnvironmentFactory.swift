import RealityKit
import RealityKitContent
import SwiftUI

/// Creates the environment and applies image-based lighting.
@MainActor
func createEnvironment(on root: Entity, appModel: AppModel) async throws {
    // Create the root entity for the environment.
    let assetRoot = Entity()
    
    // Load Lab Environment from pre-loaded assets.
    if let labEnvironmentScene = await appModel.assetLoadingManager.instantiateEntity("lab_environment") {
        assetRoot.addChild(labEnvironmentScene)
    } else {
        print("Failed to load LabEnvironment from asset manager")
    }
    
    // Load and add lab equipment.
    let equipmentScene = try await appModel.assetLoadingManager.loadPopulatedLabScene()
    assetRoot.addChild(equipmentScene)
    
    // Load the image-based lighting resource.
    guard let iblURL = Bundle.main.url(forResource: "lab_v005.2k", withExtension: "exr") else {
        fatalError("Failed to load the Image-Based Lighting file.")
    }
    let iblEnv = try await EnvironmentResource(fromImage: iblURL)
    
    // Set up image-based lighting.
    let iblEntity = Entity()
    var iblComp = ImageBasedLightComponent(source: .single(iblEnv), intensityExponent: 1.0)
    iblComp.inheritsRotation = true
    iblEntity.components.set(iblComp)
    assetRoot.components.set(ImageBasedLightReceiverComponent(imageBasedLight: iblEntity))
    assetRoot.addChild(iblEntity)
    
    // Add the environment to the root.
    root.addChild(assetRoot)
} 
