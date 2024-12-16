import Foundation
import RealityKit
import RealityKitContent

extension AssetLoadingManager {
    internal func loadIntroEnvironmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load IntroEnvironment")
            do {
                let entity = try await self.loadEntity(named: "IntroEnvironment")
                print("Successfully loaded IntroEnvironment")
                return .success(entity: entity, key: "intro_environment", category: .introEnvironment)
            } catch {
                print("Failed to load IntroEnvironment: \(error)")
                return .failure(key: "intro_environment", category: .introEnvironment, error: error)
            }
        }
        taskCount += 1
    }
    
    
    // MARK: - Private Helper Methods
    
} 
