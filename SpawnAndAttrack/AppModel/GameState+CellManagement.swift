import SwiftUI
import RealityKitContent
import RealityKit

extension GameState {
    // MARK: - Cell Management Methods
    func registerCancerCell(_ entity: Entity) {
        cancerCells.append(entity)
        if let component = entity.components[CancerCellComponent.self],
           let cellID = component.cellID {
            hitCounts[cellID] = 0
        }
        notifyCellStateChanged()
    }
    
    func removeCancerCell(_ entity: Entity) {
        if let index = cancerCells.firstIndex(where: { $0 === entity }) {
            cancerCells.remove(at: index)
            if let component = entity.components[CancerCellComponent.self],
               let cellID = component.cellID {
                hitCounts.removeValue(forKey: cellID)
            }
            notifyCellStateChanged()
        }
    }
}
