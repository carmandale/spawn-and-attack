import SwiftUI

@Observable
class CellHitTracker {
    private var hitCounts: [Int: Int] = [:] // [cellID: hitCount]
    static let requiredHits = 10
    
    func incrementHits(for cellID: Int) {
        hitCounts[cellID, default: 0] += 1
    }
    
    func hits(for cellID: Int) -> Int {
        hitCounts[cellID, default: 0]
    }
    
    func isDestroyed(cellID: Int) -> Bool {
        hits(for: cellID) >= Self.requiredHits
    }
}
