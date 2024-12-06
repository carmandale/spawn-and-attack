import Foundation
import RealityKit
import RealityKitContent

extension AssetLoadingManager {
    internal func loadAttackCancerEnvironmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load AttackCancerEnvironment")
            let entity = try await Entity(named: "AttackCancerEnvironment", in: realityKitContentBundle)
            print("Successfully loaded AttackCancerEnvironment")
            return LoadResult(entity: entity, key: "attack_cancer_environment", category: .attackCancerEnvironment)
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
