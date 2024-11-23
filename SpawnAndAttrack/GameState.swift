import SwiftUI
import RealityKit

/// Represents the different phases of the game
enum GamePhase: Equatable {
    case waitingToStart
    case loadingAssets
    case playing
    case paused
    case gameOver
}

/// Centralized game state management following the hybrid architecture pattern
@Observable
@MainActor
final class GameState {
    // MARK: - Game State
    var phase: GamePhase = .waitingToStart
    var score: Int = 0
    var isPlaying: Bool = false
    
    // MARK: - Cancer Cell State
    var leftCellHits: Int = 0
    var rightCellHits: Int = 0
    private(set) var leftCellAttachPoints: [Entity] = []
    private(set) var rightCellAttachPoints: [Entity] = []
    private(set) var usedAttachPoints: Set<Entity> = []
    private(set) var attachmentCellMap: [Entity: Bool] = [:] // true for left, false for right
    
    // MARK: - Scene Management
    private(set) weak var rootEntity: Entity?
    private(set) weak var adcTemplateEntity: Entity?
    private(set) weak var currentScene: RealityKitScene?
    
    // MARK: - Constants
    let maxHitsPerCell = 3
    let rknt = "RealityKit.NotificationTrigger"
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Scene Setup
    func configureScene(_ scene: RealityKitScene) {
        currentScene = scene
    }
    
    func setRootEntity(_ entity: Entity) {
        rootEntity = entity
    }
    
    func setADCTemplate(_ entity: Entity) {
        adcTemplateEntity = entity
    }
    
    // MARK: - Attachment Point Management
    func registerAttachmentPoints(for entity: Entity, isLeftCell: Bool) {
        Task {
            let query = EntityQuery(where: .has(AttachmentComponent.self))
            let attachPoints = entity.scene?.performQuery(query).compactMap { entity -> Entity? in
                if !entity.components.has(AttachmentStateComponent.self) {
                    entity.components.set(AttachmentStateComponent())
                }
                return entity
            } ?? []
            
            await MainActor.run {
                if isLeftCell {
                    leftCellAttachPoints = attachPoints
                } else {
                    rightCellAttachPoints = attachPoints
                }
                
                attachPoints.forEach { attachmentCellMap[$0] = isLeftCell }
            }
        }
    }
    
    func isAttachPointAvailable(_ point: Entity) -> Bool {
        !usedAttachPoints.contains(point)
    }
    
    func markAttachPointUsed(_ point: Entity) {
        usedAttachPoints.insert(point)
    }
    
    // MARK: - Game Logic
    func incrementHits(isLeftCell: Bool) {
        if isLeftCell {
            leftCellHits += 1
            if leftCellHits >= maxHitsPerCell {
                triggerCancerDeath(isLeft: true)
            }
        } else {
            rightCellHits += 1
            if rightCellHits >= maxHitsPerCell {
                triggerCancerDeath(isLeft: false)
            }
        }
    }
    
    private func triggerCancerDeath(isLeft: Bool) {
        guard let scene = currentScene else { return }
        let identifier = isLeft ? "cancerDeathLeft" : "cancerDeathRight"
        let notification = Notification(
            name: .init(rknt),
            userInfo: ["\(rknt).Scene": scene,
                      "\(rknt).Identifier": identifier]
        )
        NotificationCenter.default.post(notification)
        
        // Update game state
        score += 100
        if leftCellHits >= maxHitsPerCell && rightCellHits >= maxHitsPerCell {
            phase = .gameOver
        }
    }
    
    // MARK: - Game Flow
    func startGame() {
        phase = .playing
        isPlaying = true
        resetScore()
    }
    
    func pauseGame() {
        phase = .paused
        isPlaying = false
    }
    
    func resumeGame() {
        phase = .playing
        isPlaying = true
    }
    
    func endGame() {
        phase = .gameOver
        isPlaying = false
    }
    
    private func resetScore() {
        score = 0
        leftCellHits = 0
        rightCellHits = 0
        usedAttachPoints.removeAll()
    }
    
    // MARK: - Testing Support
    #if DEBUG
    func runADCTests() async -> Bool {
        guard let scene = currentScene else {
            print("❌ Cannot run tests: No scene available")
            return false
        }
        
        return await ADCTestHelper.runBasicTest(in: scene)
    }
    #endif
}
