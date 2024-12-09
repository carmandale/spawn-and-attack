import Foundation
import RealityKit
import RealityKitContent

/// Represents the result of loading an asset
struct LoadResult {
    let entity: Entity
    let key: String
    let category: AssetCategory
}

/// Categories of assets in the lab environment
enum AssetCategory {
    case introEnvironment
    case labEnvironment
    case labEquipment
    case buildADCEnvironment
    case attackCancerEnvironment
    case cancerCell
    case adc
}

/// Loading state of the asset manager
enum LoadingState {
    case notStarted
    case loading(progress: Float)
    case completed
    case error(Error)
}

/// Add at the top level, before the AssetLoadingManager class
enum AssetError: Error {
    case resourceNotFound
    // Add other asset-related errors as needed
}

/// Manages the loading and instantiation of assets in the lab environment
@MainActor
final class AssetLoadingManager {
    // MARK: - Properties
    
    /// Singleton instance
    static let shared = AssetLoadingManager()
    
    /// Cached entity templates for efficient cloning
    internal var entityTemplates: [String: Entity] = [:]
    
    /// Path to lab objects in RealityKitContent bundle
    internal let labObjectsPath = "Assets/Lab/Objects"
    
    /// Current loading state
    private var loadingState: LoadingState = .notStarted
    
    /// The current state of asset loading
    var state: LoadingState { loadingState }
    
    /// Loaded lab environment entity
    var labEnvironment: Entity?
    
    /// Loaded attack cancer environment entity
    var attackCancerEnvironment: Entity?
    
    // MARK: - Public Methods
    
    /// Load all assets required for the entire app
    func loadAssets() async throws {
        loadingState = .loading(progress: 0)
        
        var completedAssets = 0
        var totalAssets = 0  // Initialize task count
        
        do {
            try await withThrowingTaskGroup(of: LoadResult.self) { group in
                // Load different categories in parallel, updating totalAssets
                loadIntroEnvironmentAssets(group: &group, taskCount: &totalAssets)
                loadLabEnvironmentAssets(group: &group, taskCount: &totalAssets)
                loadLabEquipmentAssets(group: &group, taskCount: &totalAssets)
                loadBuildADCEnvironmentAssets(group: &group, taskCount: &totalAssets)
                loadAttackCancerEnvironmentAssets(group: &group, taskCount: &totalAssets)
                loadCancerCellAssets(group: &group, taskCount: &totalAssets)
                loadTreatmentAssets(group: &group, taskCount: &totalAssets)
                
                // Process results as they come in
                for try await result in group {
                    processLoadedAsset(result)
                    completedAssets += 1
                    let progress = Float(completedAssets) / Float(totalAssets)
                    loadingState = .loading(progress: progress)
                }
            }
        } catch {
            print("Error in task group: \(error)")
            loadingState = .error(error)
            throw error
        }
        
        // Verify critical assets were loaded
        guard entityTemplates["lab_environment"] != nil,
              entityTemplates["attack_cancer_environment"] != nil else {
            let error = NSError(domain: "AssetLoadingManager",
                              code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Critical environments not found in loaded assets"])
            loadingState = .error(error)
            throw error
        }
        
        loadingState = .completed
    }
    
    /// Get the current loading progress
    func loadingProgress() -> Float {
        switch loadingState {
        case .notStarted:
            return 0
        case .loading(let progress):
            return progress
        case .completed:
            return 1
        case .error:
            return 0
        }
    }
    
    /// Logs the entity hierarchy during instantiation
    func instantiateEntity(_ key: String) async -> Entity? {
        guard let template = entityTemplates[key] else {
            print("Warning: No template found for key: \(key)")
            return nil
        }
        let clone = template.clone(recursive: true)
        print("\nCloned entity for key: \(key)")
//        inspectEntityHierarchy(clone)
        return clone
    }
    
    internal func processLoadedAsset(_ result: LoadResult) {
        entityTemplates[result.key] = result.entity
    }
    
    // MARK: - Memory Management
    
    /// Clear unused templates when memory pressure is high
    func handleMemoryWarning() {
        // Keep essential templates, clear others that can be reloaded
        let essentialKeys = ["lab_environment", "cancer_cell"]
        entityTemplates = entityTemplates.filter { essentialKeys.contains($0.key) }
    }
    
    internal func validateTemplate(_ entity: Entity, category: AssetCategory) async {
        print("\n=== Validating \(category) Template ===")
        inspectEntityHierarchy(entity, level: 0)
    }
    
    /// Debug utility to inspect entity hierarchies
    public func inspectEntityHierarchy(_ entity: Entity, level: Int = 0, showComponents: Bool = true) {
        let indent = String(repeating: "  ", count: level)
        print("\(indent)Entity: \(entity.name)")
        if showComponents {
            print("\(indent)Components: \(entity.components.map { type(of: $0) })")
        }
        
        for child in entity.children {
            inspectEntityHierarchy(child, level: level + 1, showComponents: showComponents)
        }
    }
    
    /// Load an entity by name, using caching to avoid redundant loads
    func loadEntity(named name: String) async throws -> Entity {
        if let cachedEntity = entityTemplates[name] {
            return cachedEntity.clone(recursive: true)
        }

        let entity = try await Entity(named: name, in: realityKitContentBundle)
        entityTemplates[name] = entity
        return entity.clone(recursive: true)
    }
}
