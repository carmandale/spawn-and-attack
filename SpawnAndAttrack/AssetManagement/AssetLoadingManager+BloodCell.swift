import Foundation
import RealityKit
import RealityKitContent

extension AssetLoadingManager {
    internal func loadBuildADCEnvironmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask { [weak self] in
            guard let self = self else { throw AssetLoadError.loadFailed("AssetLoadingManager deallocated") }
            print("Starting to load BuildADCEnvironment")
            let entity = try await self.loadEntity(named: "BuildADCEnvironment")
            print("Successfully loaded BuildADCEnvironment")
            return LoadResult(entity: entity, key: "build_adc_environment", category: .buildADCEnvironment)
        }
        taskCount += 1
    }
    
    
    // MARK: - Private Helper Methods
    
} 
