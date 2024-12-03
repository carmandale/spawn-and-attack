import Foundation
import RealityKit
import RealityKitContent

extension AssetLoadingManager {
    internal func loadLabEnvironmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        group.addTask {
            print("Starting to load LabEnvironment")
            let entity = try await Entity(named: "LabEnvironment", in: realityKitContentBundle)
            print("Successfully loaded LabEnvironment")
            return LoadResult(entity: entity, key: "lab_environment", category: .labEnvironment)
        }
        taskCount += 1
    }
    
    internal func loadLabEquipmentAssets(group: inout ThrowingTaskGroup<LoadResult, Error>, taskCount: inout Int) {
        let labAssets = [
            "autoclave", "beaker", "beaker_tall", "bin", "bottle_liquid",
            "bottle_pill", "bottle_square", "bottle_squat", "centrifuge",
            "chair", "deskShelf_double", "deskShelf_single", "desktopPC",
            "dish", "dryingRack", "flask_conical", "flask_conical_lg",
            "flask_flatBottom", "flask_flatBottom_lg", "flask_volumetric",
            "flask_volumetric_lg", "fridge_sm", "glovesBox_A", "glovesBox_B",
            "jar_pill", "jar_pill_sm", "laptop", "mettlerBalance",
            "mettlerBalance_box", "microscope", "oven", "pcKeyboard",
            "pcMonitor", "pcMouse", "pcTower", "shaker", "squirter",
            "stool", "testTubes_lg_set", "testTubes_sm_set", "tester",
            "uvBox", "vortex", "wasteBasket"
        ]
        
        for assetName in labAssets {
            group.addTask {
                print("Starting to load asset: \(assetName)")
                let entity = try await Entity(named: "\(self.labObjectsPath)/\(assetName)", in: realityKitContentBundle)
                print("Successfully loaded asset: \(assetName)")
                return LoadResult(entity: entity, key: assetName, category: .labEquipment)
            }
            taskCount += 1
        }
    }
    
    /// Load and populate a complete lab scene
    func loadPopulatedLabScene() async throws -> Entity {
        // Load the empty lab scene
        let emptyScene = try await Entity(named: "\(labObjectsPath)/lab_empties", in: realityKitContentBundle)
        
        // Find all empty transforms
        let emptyTransforms = findEmptyTransforms(in: emptyScene)
        
        // Process each empty transform
        for empty in emptyTransforms {
            if let assetName = extractAssetName(from: empty.name) {
                // Load or get cached asset
                let asset = try await loadLabAsset(named: assetName)
                
                // Clone and parent
                let instance = asset.clone(recursive: true)
                empty.addChild(instance)
                
                // Configure the instance
                configureLabInstance(instance, for: empty)
            }
        }
        
        // Apply final scene rotation
        emptyScene.orientation = simd_quatf(angle: -.pi/2, axis: [1, 0, 0])
        
        return emptyScene
    }
    
    // MARK: - Private Helper Methods
    
    private func findEmptyTransforms(in scene: Entity) -> [Entity] {
        var empties: [Entity] = []
        
        func traverse(entity: Entity) {
            if entity.name.hasPrefix("empty_") {
                empties.append(entity)
            }
            
            for child in entity.children {
                traverse(entity: child)
            }
        }
        
        traverse(entity: scene)
        return empties
    }
    
    private func extractAssetName(from name: String) -> String? {
        // Remove the prefix "empty_" and the suffix "_<number>"
        let prefix = "empty_"
        guard name.hasPrefix(prefix) else { return nil }
        let nameWithoutPrefix = String(name.dropFirst(prefix.count))
        
        // Find the last underscore which precedes the number
        if let lastUnderscoreIndex = nameWithoutPrefix.lastIndex(of: "_") {
            let assetName = nameWithoutPrefix[..<lastUnderscoreIndex]
            return String(assetName)
        } else {
            // If there's no underscore, return the entire name
            return nameWithoutPrefix
        }
    }
    
    private func loadLabAsset(named assetName: String) async throws -> Entity {
        if let cached = entityTemplates[assetName] {
            return cached
        }
        
        let asset = try await Entity(named: "\(labObjectsPath)/\(assetName)", in: realityKitContentBundle)
        entityTemplates[assetName] = asset
        return asset
    }
    
    private func configureLabInstance(_ instance: Entity, for empty: Entity) {
        instance.position = .zero
        instance.orientation = .init()
        instance.scale = .one
    }
} 