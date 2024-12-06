import Foundation
import RealityKit
import RealityKitContent

extension AssetLoadingManager {
    internal func loadIntroEnvironmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load IntroEnvironment")
            let entity = try await Entity(named: "IntroEnvironment", in: realityKitContentBundle)
            print("Successfully loaded IntroEnvironment")
            return LoadResult(entity: entity, key: "intro_environment", category: .introEnvironment)
        }
        taskCount += 1
    }
    
    
    // MARK: - Private Helper Methods
    
} 
