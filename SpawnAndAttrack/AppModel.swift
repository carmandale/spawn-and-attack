import SwiftUI
import RealityKit
import RealityKitContent

/// Maintains app-wide state for the cancer cell targeting game
@Observable
@MainActor
class AppModel: HitCountTracking {
    // MARK: - Game State
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    var immersiveSpaceState: ImmersiveSpaceState = .closed
    var immersiveSpaceID = "ImmersiveSpace"
    
    // Systems
    var cancerCellSystem: CancerCellSystem?
    var adcMovementSystem: ADCMovementSystem?
    
    // Game stats (observable properties)
    var score = 0
    var totalHits = 0
    var cellsDestroyed = 0
    
    // Hit count tracking
    @MainActor
    private var hitCounts: [Int: Int] = [:]
    
    init() {
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCancerCellUpdate),
            name: Notification.Name("UpdateCancerCell"),
            object: nil
        )
    }
    
    @objc private func handleCancerCellUpdate(_ notification: Notification) {
        guard let entity = notification.userInfo?["entity"] as? Entity,
              let component = entity.components[CancerCellComponent.self],
              let cellID = component.cellID else {
            return
        }
        
        // Update our local tracking
        hitCounts[cellID] = component.hitCount
        
        // Update the cancer cells array
        if let index = cancerCells.firstIndex(where: { 
            $0.components[CancerCellComponent.self]?.cellID == cellID 
        }) {
            cancerCells[index] = entity
        } else {
            cancerCells.append(entity)
        }
    }
    
    @MainActor
    func getHitCount(for cellID: Int) -> Int {
        return hitCounts[cellID] ?? 0
    }
    
    @MainActor
    func updateHitCount(for cellID: Int, count: Int) {
        hitCounts[cellID] = count
    }
    
    // MARK: - Cell Management
    static let maxCancerCells = 5  // Start with 5 cells for testing
    var cancerCells: [Entity] = []  // Track active cells for game state
    
    // MARK: - Spawn Configuration
    let spawnBounds = BoundingBox(
        min: [-5, -2, -5],
        max: [5, 2, 5]
    )
    
    struct MovementConfig {
        static let minSpeed: Float = 0.5
        static let maxSpeed: Float = 1.5
        static let rotationRange: Float = .pi * 2
    }
    
    // MARK: - Cell Tracking Methods
    func registerCancerCell(_ entity: Entity) {
        cancerCells.append(entity)
    }
    
    func removeCancerCell(_ entity: Entity) {
        if let index = cancerCells.firstIndex(where: { $0 === entity }) {
            cancerCells.remove(at: index)
        }
    }
    
    // MARK: - Game State Methods
    func resetGame() {
        score = 0
        totalHits = 0
        cellsDestroyed = 0
        cancerCells.removeAll()
    }
}
