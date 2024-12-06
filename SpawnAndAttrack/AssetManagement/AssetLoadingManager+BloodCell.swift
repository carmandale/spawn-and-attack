import Foundation
import RealityKit
import RealityKitContent

extension AssetLoadingManager {
    internal func loadBuildADCEnvironmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load BuildADCEnvironment")
            let entity = try await Entity(named: "BuildADCEnvironment", in: realityKitContentBundle)
            print("Successfully loaded BuildADCEnvironment")
            return LoadResult(entity: entity, key: "build_adc_environment", category: .buildADCEnvironment)
        }
        taskCount += 1
    }
    
    
    // MARK: - Private Helper Methods
    
} 
