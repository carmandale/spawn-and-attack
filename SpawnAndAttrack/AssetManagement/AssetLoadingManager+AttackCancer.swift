import Foundation
import RealityKit
import RealityKitContent

enum AssetLoadError: Error {
    case loadFailed(String)
}

extension AssetLoadingManager {
    
    internal func loadAttackCancerEnvironmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load and assemble AttackCancerEnvironment")
            
            let assetRoot = await Entity()
            
            // Load base environment
            let attackCancerScene = try await Entity(named: "AttackCancerEnvironment", in: realityKitContentBundle)
            await assetRoot.addChild(attackCancerScene)
            
            // Add IBL
            try await IBLUtility.addImageBasedLighting(to: assetRoot, imageName: "metro_noord_2k")
            
            print("Successfully assembled AttackCancerEnvironment")
            return LoadResult(entity: assetRoot, key: "attack_cancer_environment", category: .attackCancerEnvironment)
        }
        taskCount += 1
    }
    
    internal func loadCancerCellAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load CancerCell-spawn")
            let entity = try await Entity(named: "CancerCell-spawn", in: realityKitContentBundle)
            
            print("Successfully loaded CancerCell-spawn")
            return LoadResult(entity: entity, key: "cancer_cell", category: .cancerCell)
        }
        taskCount += 1
    }
    
    internal func loadTreatmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load ADC-spawn")
            let adc = try await Entity(named: "ADC-spawn", in: realityKitContentBundle)
            print("Successfully loaded ADC-spawn")
            // Store the inner root with audio like in the original
            if let innerRoot = await adc.children.first {
                return LoadResult(entity: innerRoot, key: "adc", category: .adc)
            }
            return LoadResult(entity: adc, key: "adc", category: .adc)
        }
        taskCount += 1
    }
} 
