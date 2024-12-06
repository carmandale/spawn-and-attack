import Foundation
import RealityKit
import RealityKitContent

extension AssetLoadingManager {
    internal func loadBloodCellEnvironmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load BloodCellEnvironment")
            let entity = try await Entity(named: "BloodCellEnvironment", in: realityKitContentBundle)
            print("Successfully loaded BloodCellEnvironment")
            return LoadResult(entity: entity, key: "blood_cell_environment", category: .bloodCellEnvironment)
        }
        taskCount += 1
    }
    
    
    // MARK: - Private Helper Methods
    
} 
