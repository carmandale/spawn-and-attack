import SwiftUI
import RealityKitContent
import RealityKit

extension GameState {
    // MARK: - Notification Setup
    func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCancerCellUpdate),
            name: Notification.Name("UpdateCancerCell"),
            object: nil
        )
    }
    
    @objc func handleCancerCellUpdate(_ notification: Notification) {
        guard let entity = notification.userInfo?["entity"] as? Entity,
              let component = entity.components[CancerCellComponent.self],
              let cellID = component.cellID else {
            return
        }
        
        // Update hit count tracking
        hitCounts[cellID] = component.hitCount
        
        // Update cancer cells array
        if let index = cancerCells.firstIndex(where: {
            $0.components[CancerCellComponent.self]?.cellID == cellID
        }) {
            cancerCells[index] = entity
        } else {
            cancerCells.append(entity)
        }
        
        // Update game stats
        totalHits = hitCounts.values.reduce(0, +)
        cellsDestroyed = cancerCells.filter { cell in
            guard let component = cell.components[CancerCellComponent.self] else { return false }
            return component.hitCount >= component.requiredHits
        }.count
        
        // Update score
        score = cellsDestroyed * 100 + totalHits * 10
        
        // Check game conditions and notify state changes
        checkGameConditions()
        notifyCellStateChanged()
        notifyGameStateChanged()
        notifyScoreChanged()
    }
    
    @objc func handleCellDeathComplete(_ notification: Notification) {
        guard let cellID = notification.userInfo?["cellID"] as? Int else { return }
        
        completedDeaths.insert(cellID)
        
        // Check if all cells are destroyed
        if completedDeaths.count >= maxCancerCells {
            // Wait for death animations to complete
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                appModel.currentPhase = .completed
            }
        }
    }
    
    func notifyCellStateChanged() {
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
    
    // MARK: - HitCountTracking Protocol Implementation
    @MainActor
    func getHitCount(for cellID: Int) -> Int {
        return hitCounts[cellID] ?? 0
    }
    
    @MainActor
    func updateHitCount(for cellID: Int, count: Int) {
        hitCounts[cellID] = count
    }
    
    // MARK: - Game State Observation
    private func notifyGameStateChanged() {
        guard let appModel = appModel else { return }
        onGameStateChanged?(appModel.currentPhase)
    }
    
    private func notifyScoreChanged() {
        onScoreChanged?(score)
    }
}
