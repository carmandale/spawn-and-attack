// import SwiftUI
// import RealityKit
// import RealityKitContent

// /// Maintains app-wide state for the cancer cell targeting game
// @Observable
// @MainActor
// class AppModel: HitCountTracking {
//     // MARK: - App Phases

//     enum Phase: String {
//         case waitingToStart
//         case loadingAssets
//         case intro
//         case lab
//         case attack
//     }

//     var phase: Phase = .waitingToStart

//     // Reference to the shared AssetLoadingManager
//     let assetLoadingManager = AssetLoadingManager.shared

//     // Methods to handle phase transitions

//     func transitionToIntro() {
//         phase = .loadingAssets
//         phase = .intro
//     }

//     func transitionToLab() async {
//         phase = .loadingAssets
//         phase = .lab
//     }

//     func transitionToAttackCancer() async {
//         phase = .loadingAssets
//         phase = .attack
//     }

//     // MARK: - Game State
//     enum ImmersiveSpaceState {
//         case closed
//         case inTransition
//         case open
//     }
    
//     enum ImmersiveSpaceID: String {
//         case attackCancer = "attack_cancer_space"
//         case lab = "lab_space"
//         case intro = "intro_space"
//     }
    
//     var currentSpace: ImmersiveSpaceID?
//     var immersiveSpaceIsShown = false
//     var immersiveSpaceState: ImmersiveSpaceState = .closed
    
//     // Systems
//     var cancerCellSystem: CancerCellSystem?
//     var adcMovementSystem: ADCMovementSystem?
    
//     // Game stats (observable properties)
//     var score = 0
//     var totalHits = 0
//     var cellsDestroyed = 0
    
//     // Hit count tracking
//     @MainActor
//     private var hitCounts: [Int: Int] = [:]
    
//     // Add these new properties
//     var immersiveSpaceActive: Bool = false
//     var currentImmersiveSpaceID: String?
    
//     init() {
//         setupNotifications()
//     }
    
//     deinit {
//         NotificationCenter.default.removeObserver(self)
//     }
    
//     private func setupNotifications() {
//         NotificationCenter.default.addObserver(
//             self,
//             selector: #selector(handleCancerCellUpdate),
//             name: Notification.Name("UpdateCancerCell"),
//             object: nil
//         )
//     }
    
//     @objc private func handleCancerCellUpdate(_ notification: Notification) {
//         guard let entity = notification.userInfo?["entity"] as? Entity,
//               let component = entity.components[CancerCellComponent.self],
//               let cellID = component.cellID else {
//             return
//         }
        
//         // Update our local tracking
//         hitCounts[cellID] = component.hitCount
        
//         // Update the cancer cells array
//         if let index = cancerCells.firstIndex(where: { 
//             $0.components[CancerCellComponent.self]?.cellID == cellID 
//         }) {
//             cancerCells[index] = entity
//         } else {
//             cancerCells.append(entity)
//         }
//     }
    
//     @MainActor
//     func getHitCount(for cellID: Int) -> Int {
//         return hitCounts[cellID] ?? 0
//     }
    
//     @MainActor
//     func updateHitCount(for cellID: Int, count: Int) {
//         hitCounts[cellID] = count
//     }
    
//     // MARK: - Cell Management
//     static let maxCancerCells = 5  // Start with 5 cells for testing
//     var cancerCells: [Entity] = []  // Track active cells for game state
    
//     // MARK: - Spawn Configuration
//     let spawnBounds = BoundingBox(
//         min: [-5, -2, -5],
//         max: [5, 2, 5]
//     )
    
//     struct MovementConfig {
//         static let minSpeed: Float = 0.5
//         static let maxSpeed: Float = 1.5
//         static let rotationRange: Float = .pi * 2
//     }
    
//     // MARK: - Cell Tracking Methods
//     func registerCancerCell(_ entity: Entity) {
//         cancerCells.append(entity)
//     }
    
//     func removeCancerCell(_ entity: Entity) {
//         if let index = cancerCells.firstIndex(where: { $0 === entity }) {
//             cancerCells.remove(at: index)
//         }
//     }
    
//     // MARK: - Game State Methods
//     func resetGame() {
//         score = 0
//         totalHits = 0
//         cellsDestroyed = 0
//         cancerCells.removeAll()
//     }
    
//     // MARK: - Collision Handling
//     private var debounce: [UnorderedPair<Entity>: TimeInterval] = [:]
//     private static let debounceThreshold: TimeInterval = 0.1
    
//     func handleCollisionBegan(_ collision: CollisionEvents.Began) {
//         guard shouldHandleCollision(collision) else { 
//             // print("Collision debounced")
//             return 
//         }
        
//         let entities = UnorderedPair(collision.entityA, collision.entityB)
//         let impulse = collision.impulse
        
//         // print("\n=== Collision Details ===")
//         // print("Entity A: \(collision.entityA.name)")
//         // print("Entity A components: \(collision.entityA.components)")
//         // print("Entity B: \(collision.entityB.name)")
//         // print("Entity B components: \(collision.entityB.components)")
//         // print("Impulse: \(impulse)")
//         // print("Impulse Direction: \(collision.impulseDirection)")
//         // print("Contact Position: \(collision.position)")
        
//         // Handle cell-to-cell collisions
//         if let cellA = entities.itemA.components[CancerCellComponent.self],
//            let cellB = entities.itemB.components[CancerCellComponent.self] {
//             // print("\nCell-to-cell collision detected")
//             // print("Cell A ID: \(cellA.cellID ?? -1)")
//             // print("Cell B ID: \(cellB.cellID ?? -1)")
            
//             if let motionA = entities.itemA.components[PhysicsMotionComponent.self],
//                let motionB = entities.itemB.components[PhysicsMotionComponent.self] {
//                 let impulseStrength = impulse * 0.2
//                 entities.itemA.components[PhysicsMotionComponent.self]?.linearVelocity += collision.impulseDirection * impulseStrength
//                 entities.itemB.components[PhysicsMotionComponent.self]?.linearVelocity -= collision.impulseDirection * impulseStrength
//                 // print("Applied collision forces to both cells")
//                 // print("Impulse strength: \(impulseStrength)")
//             } else {
//                 print("Missing PhysicsMotionComponent on one or both cells")
//             }
//         }
        
//         // Handle ADC-to-cell collisions - this is handled by ADCMovementSystem
//     }
    
//     private func shouldHandleCollision(_ collision: CollisionEvents.Began) -> Bool {
//         let entities = UnorderedPair(collision.entityA, collision.entityB)
//         let now = CACurrentMediaTime()
//         if let reference = debounce[entities] {
//             if now - reference < Self.debounceThreshold {
//                 return false
//             }
//         }
//         debounce[entities] = now
//         return true
//     }

//     // MARK: - Asset Loading
//     var loadingProgress: Float = 0
//     var isLoading = false
    
//     func startLoading() async {
//         phase = .loadingAssets
//         isLoading = true
//         do {
//             // Start progress monitoring
//             Task {
//                 while assetLoadingManager.loadingProgress() < 1.0 {
//                     loadingProgress = assetLoadingManager.loadingProgress()
//                     try? await Task.sleep(nanoseconds: 100_000_000)
//                 }
//                 loadingProgress = assetLoadingManager.loadingProgress()
//             }
            
//             try await assetLoadingManager.loadAssets()
//             isLoading = false
//             phase = .intro  // Go to intro after loading
//         } catch {
//             print("Error loading assets: \(error)")
//             isLoading = false
//         }
//     }


// }
