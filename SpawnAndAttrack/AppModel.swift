import SwiftUI
import RealityKit
import RealityKitContent

/// Maintains app-wide state for the cancer cell targeting game
/// This class is responsible for:
/// 1. Game State Management: Handles core game mechanics and state transitions
/// 2. Cell Management: Tracks and updates cancer cell entities
/// 3. Collision Detection: Manages cell-to-cell and ADC-to-cell interactions
/// 4. Score Tracking: Maintains hit counts and overall game score
@Observable
@MainActor
final class AppModel: HitCountTracking {
    // MARK: - Space Management
    enum SpaceState: String, Identifiable, CaseIterable {
        case intro
        case lab
        case attack
        
        var id: Self { self }
        var name: String { rawValue.capitalized }
        var spaceId: String { rawValue + "Space" }
    }
    
    // MARK: - Window Management
    static let adcBuilderWindowId = "ADCBuilder"
    static let adcVolumetricWindowId = "ADCVolumetric"
    static let debugNavigationWindowId = "DebugNavigation"
    
    enum WindowState {
        case adcBuilder
        case adcVolumetric
        case debugNavigation
        
        var windowId: String {
            switch self {
            case .adcBuilder: return AppModel.adcBuilderWindowId
            case .adcVolumetric: return AppModel.adcVolumetricWindowId
            case .debugNavigation: return AppModel.debugNavigationWindowId
            }
        }
        
        var shouldShowInLabSpace: Bool {
            switch self {
            case .adcBuilder, .adcVolumetric: return true
            case .debugNavigation: return false
            }
        }
    }
    
    // Window visibility state
    var isShowingADCBuilder: Bool = false {
        didSet {
            handleWindowVisibility(.adcBuilder, isShowing: isShowingADCBuilder)
        }
    }
    var isShowingADCVolumetric: Bool = false {
        didSet {
            handleWindowVisibility(.adcVolumetric, isShowing: isShowingADCVolumetric)
        }
    }
    var isShowingDebugNavigation: Bool = false {
        didSet {
            handleWindowVisibility(.debugNavigation, isShowing: isShowingDebugNavigation)
        }
    }
    
    private func handleWindowVisibility(_ window: WindowState, isShowing: Bool) {
        // This will be called by the environment openWindow/dismissWindow actions
        // We don't need to implement anything here as it's just for state tracking
    }

    // MARK: - Space State
    var introSpaceActive: Bool = false {
        didSet {
            if !introSpaceActive {
                // Clean up when space becomes inactive
            }
        }
    }
    
    var labSpaceActive: Bool = false {
        didSet {
            if labSpaceActive {
                isShowingADCBuilder = true
                isShowingADCVolumetric = true
            } else {
                isShowingADCBuilder = false
                isShowingADCVolumetric = false
            }
        }
    }
    
    var attackSpaceActive: Bool = false {
        didSet {
            if !attackSpaceActive {
                // Clean up when space becomes inactive
            }
        }
    }

    var immersiveSpaceActive: Bool {
        return introSpaceActive || labSpaceActive || attackSpaceActive
    }

    // MARK: - Game State
    /// Represents the current phase of the game
    /// - setup: Initial state, systems being initialized
    /// - playing: Active gameplay
    /// - paused: Game temporarily suspended
    /// - completed: Game finished (win/loss condition met)
    /// - error: Game finished due to an error
    enum GamePhase {
        case setup
        case playing
        case paused
        case completed
        case error
    }
    
    /// Current phase of the game
    var gamePhase: GamePhase = .setup
    
    // MARK: - Game Systems
    /// System responsible for cancer cell behavior and spawning
    var cancerCellSystem: CancerCellSystem?
    
    /// System handling ADC movement and interactions
    var adcMovementSystem: ADCMovementSystem?
    
    // MARK: - Game Stats and Tracking
    /// Overall game score, calculated from hits and destroyed cells
    var score: Int = 0
    
    // MARK: - Game Stats and Tracking
    /// Total number of successful hits across all cells
    var totalHits = 0
    
    /// Number of cells completely destroyed (3 hits)
    var cellsDestroyed = 0
    
    // Hit count tracking
    private var hitCounts: [Int: Int] = [:]
    
    // MARK: - Hit Count Tracking
    var hitCount: Int = 0
    var totalCellsDestroyed: Int = 0
    var totalADCsDeployed: Int = 0
    
    func incrementHitCount() {
        hitCount += 1
    }
    
    func incrementCellsDestroyed() {
        totalCellsDestroyed += 1
    }
    
    func incrementADCsDeployed() {
        totalADCsDeployed += 1
    }
    
    func resetHitCounts() {
        hitCount = 0
        totalCellsDestroyed = 0
        totalADCsDeployed = 0
    }
    
    // MARK: - Game Configuration
    /// Difficulty level of the game, affecting spawn rates and cell behavior
    var difficulty: Float = 1.0
    
    /// Time interval between cancer cell spawns
    var spawnRate: TimeInterval = 2.0
    
    /// Maximum number of cells allowed on screen
    static let maxCancerCells: Int = 10
    
    // MARK: - Asset Management
    let assetLoadingManager = AssetLoadingManager.shared

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
        
        // Update cell state
        var state = cellStates[cellID] ?? CellState(hitCount: 0, isDestroyed: false, lastHitTime: 0)
        state.hitCount = component.hitCount
        state.isDestroyed = component.hitCount >= 3
        state.lastHitTime = Date().timeIntervalSinceReferenceDate
        cellStates[cellID] = state
        
        // Update game stats
        totalHits = cellStates.values.map { $0.hitCount }.reduce(0, +)
        cellsDestroyed = cellStates.values.filter { $0.isDestroyed }.count
        
        // Update score and notify
        score = cellsDestroyed * 100 + totalHits * 10
        
        // Check game conditions and notify state changes
        checkGameConditions()
        notifyCellStateChanged()
    }
    
    // MARK: - Cell Management
    private(set) var cancerCells: [Entity] = []  // Track active cells for game state
    
    /// Tracks the state of each cancer cell
    private var cellStates: [Int: CellState] = [:]
    
    struct CellState {
        var hitCount: Int
        var isDestroyed: Bool
        var lastHitTime: TimeInterval
    }
    
    // MARK: - Cell Management Methods
    func registerCancerCell(_ entity: Entity) {
        cancerCells.append(entity)
        if let component = entity.components[CancerCellComponent.self],
           let cellID = component.cellID {
            cellStates[cellID] = CellState(hitCount: 0, isDestroyed: false, lastHitTime: 0)
        }
        notifyCellStateChanged()
    }
    
    func removeCancerCell(_ entity: Entity) {
        if let index = cancerCells.firstIndex(where: { $0 === entity }) {
            cancerCells.remove(at: index)
            if let component = entity.components[CancerCellComponent.self],
               let cellID = component.cellID {
                cellStates.removeValue(forKey: cellID)
            }
            notifyCellStateChanged()
        }
    }
    
    private func notifyCellStateChanged() {
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .init("CellStateChanged"),
            object: self,
            userInfo: [
                "totalHits": totalHits,
                "cellsDestroyed": cellsDestroyed,
                "score": score
            ]
        )
    }
    
    // MARK: - Game Conditions
    private func checkGameConditions() {
        // Check for game completion
        if totalCellsDestroyed >= Self.maxCancerCells {
            gamePhase = .completed
        }
    }
    
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
    
    // MARK: - Game Methods
    func startGame() {
        gamePhase = .playing
        score = 0
        totalHits = 0
        cellsDestroyed = 0
    }
    
    func pauseGame() {
        gamePhase = .paused
    }
    
    func resumeGame() {
        gamePhase = .playing
    }
    
    func endGame() {
        gamePhase = .completed
    }
    
    func resetGameState() {
        gamePhase = .setup
        score = 0
        totalHits = 0
        cellsDestroyed = 0
    }
    
    // MARK: - Game State Observation
    var onGameStateChanged: ((GamePhase) -> Void)?
    var onScoreChanged: ((Int) -> Void)?
    
    private func notifyGameStateChanged() {
        onGameStateChanged?(gamePhase)
    }
    
    private func notifyScoreChanged() {
        onScoreChanged?(score)
    }
    
    // MARK: - Asset Loading
    var isLoadingAssets: Bool {
        if case .loading = assetLoadingManager.state {
            return true
        }
        return false
    }
    
    var assetsLoaded: Bool {
        if case .completed = assetLoadingManager.state {
            return true
        }
        return false
    }
    
    var loadingProgress: Float = 0
    var isLoading = false
    
    func startLoading() async {
        isLoading = true
        do {
            // Start progress monitoring
            Task {
                while assetLoadingManager.loadingProgress() < 1.0 {
                    loadingProgress = assetLoadingManager.loadingProgress()
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                loadingProgress = assetLoadingManager.loadingProgress()
            }
            
            try await assetLoadingManager.loadAssets()
            isLoading = false

            // Update gamePhase to indicate loading is complete
            gamePhase = .playing
            
        } catch {
            print("Error loading assets: \(error)")
            isLoading = false

            // Handle error by setting gamePhase or presenting an error message
            gamePhase = .error
        }
    }
    
    func getHitCount(for cellID: Int) -> Int {
        return hitCounts[cellID] ?? 0
    }
    
    func updateHitCount(for cellID: Int, count: Int) {
        hitCounts[cellID] = count
    }
    
    // MARK: - Collision Handling
    private var debounce: [UnorderedPair<Entity>: TimeInterval] = [:]
    private static let debounceThreshold: TimeInterval = 0.1
    
    func handleCollisionBegan(_ collision: CollisionEvents.Began) {
        guard shouldHandleCollision(collision) else { 
            // print("Collision debounced")
            return 
        }
        
        let entities = UnorderedPair(collision.entityA, collision.entityB)
        let impulse = collision.impulse
        
        // print("\n=== Collision Details ===")
        // print("Entity A: \(collision.entityA.name)")
        // print("Entity A components: \(collision.entityA.components)")
        // print("Entity B: \(collision.entityB.name)")
        // print("Entity B components: \(collision.entityB.components)")
        // print("Impulse: \(impulse)")
        // print("Impulse Direction: \(collision.impulseDirection)")
        // print("Contact Position: \(collision.position)")
        
        // Handle cell-to-cell collisions
        if let cellA = entities.itemA.components[CancerCellComponent.self],
           let cellB = entities.itemB.components[CancerCellComponent.self] {
            // print("\nCell-to-cell collision detected")
            // print("Cell A ID: \(cellA.cellID ?? -1)")
            // print("Cell B ID: \(cellB.cellID ?? -1)")
            
            if let motionA = entities.itemA.components[PhysicsMotionComponent.self],
               let motionB = entities.itemB.components[PhysicsMotionComponent.self] {
                let impulseStrength = impulse * 0.2
                entities.itemA.components[PhysicsMotionComponent.self]?.linearVelocity += collision.impulseDirection * impulseStrength
                entities.itemB.components[PhysicsMotionComponent.self]?.linearVelocity -= collision.impulseDirection * impulseStrength
                // print("Applied collision forces to both cells")
                // print("Impulse strength: \(impulseStrength)")
            } else {
                print("Missing PhysicsMotionComponent on one or both cells")
            }
        }
        
        // Handle ADC-to-cell collisions - this is handled by ADCMovementSystem
    }
    
    private func shouldHandleCollision(_ collision: CollisionEvents.Began) -> Bool {
        let entities = UnorderedPair(collision.entityA, collision.entityB)
        let now = CACurrentMediaTime()
        if let reference = debounce[entities] {
            if now - reference < Self.debounceThreshold {
                return false
            }
        }
        debounce[entities] = now
        return true
    }
    
    // MARK: - Immersive Space Management
    func setImmersiveSpaceActive(spaceID: String, isActive: Bool) {
        switch spaceID {
        case "IntroSpace":
            introSpaceActive = isActive
        case "LabSpace":
            labSpaceActive = isActive
        case "AttackSpace":
            attackSpaceActive = isActive
        default:
            break
        }
    }
}
