import SwiftUI
import RealityKit
import RealityKitContent

@Observable @MainActor
final class AttackCancerViewModel {
    // MARK: - State
    var totalTaps: Int = 0
    var successfulADCLaunches: Int = 0
    var rootEntity: Entity?
    var adcTemplate: Entity?
    
    // MARK: - Dependencies
    let appModel: AppModel
    let handTracking: HandTrackingViewModel
    
    // Store subscription to prevent deallocation
    private var subscription: EventSubscription?
    
    // Additional properties from view
    var handTrackedEntity: Entity
    var scene: RealityKit.Scene?
    
    // MARK: - Initialization
    init(appModel: AppModel, handTracking: HandTrackingViewModel) {
        self.appModel = appModel
        self.handTracking = handTracking
        
        // Initialize handTrackedEntity
        self.handTrackedEntity = {
            let handAnchor = AnchorEntity(.hand(.left, location: .aboveHand))
            return handAnchor
        }()
    }
    
    // MARK: - Setup Functions
    func setupRoot() -> Entity {
        let root = Entity()
        rootEntity = root
        return root
    }
    
    func setupEnvironment(in root: Entity) async {
        // IBL
        do {
            try await IBLUtility.addImageBasedLighting(to: root, imageName: "metro_noord_2k")
        } catch {
            print("Failed to setup IBL: \(error)")
        }
        
        // Environment
        if let attackCancerScene = await appModel.assetLoadingManager.instantiateEntity("attack_cancer_environment") {
            root.addChild(attackCancerScene)
            setupCollisions(in: attackCancerScene)
        }
    }
    
    private func setupCollisions(in scene: Entity) {
        if let scene = scene.scene {
            let query = EntityQuery(where: .has(BloodVesselWallComponent.self))
            let objectsToModify = scene.performQuery(query)
            
            for object in objectsToModify {
                if var collision = object.components[CollisionComponent.self] {
                    collision.filter.group = .cancerCell
                    collision.filter.mask = .adc
                    object.components[CollisionComponent.self] = collision
                }
            }
        }
    }
    
    // MARK: - Tap Handling
    func handleTap(on entity: Entity, location: SIMD3<Float>) async {
        print("Tapped entity: \(entity.name)")
        
        // Get pinch distances for both hands to determine which hand tapped
        let leftPinchDistance = handTracking.getPinchDistance(.left) ?? Float.infinity
        let rightPinchDistance = handTracking.getPinchDistance(.right) ?? Float.infinity
        
        // Determine which hand's position to use
        let handPosition: SIMD3<Float>?
        if leftPinchDistance < rightPinchDistance {
            handPosition = handTracking.getFingerPosition(.left)
            print("Left hand tap detected")
        } else{
            handPosition = handTracking.getFingerPosition(.right)
            print("Right hand tap detected")
        }
        
        // Proceed with existing cancer cell logic
        guard let scene = scene,
              let cellComponent = entity.components[CancerCellComponent.self],
              let cellID = cellComponent.cellID else {
            print("No scene available or no cell component/ID")
            return
        }
        print("Found cancer cell with ID: \(cellID)")
        
        guard let attachPoint = AttachmentSystem.getAvailablePoint(in: scene, forCellID: cellID) else {
            print("No available attach point found")
            return
        }
        print("Found attach point: \(attachPoint.name)")
        
        AttachmentSystem.markPointAsOccupied(attachPoint)
        
        // Use the detected hand position if available, otherwise fall back to tap location
        let spawnPosition = handPosition ?? location
        await spawnADC(from: spawnPosition, targetPoint: attachPoint, forCellID: cellID)
    }
    
    // MARK: - Collision Subscription
    func setupCollisionSubscription(in content: RealityViewContent) {
        subscription = content.subscribe(to: CollisionEvents.Began.self) { [weak appModel] event in
            appModel?.gameState.handleCollisionBegan(event)
        }
    }
} 