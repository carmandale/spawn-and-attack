import Foundation

@MainActor
public protocol HitCountTracking: AnyObject {
    func getHitCount(for cellID: Int) -> Int
    func updateHitCount(for cellID: Int, count: Int)
}
