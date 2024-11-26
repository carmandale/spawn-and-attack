import RealityKit

@MainActor
public struct CancerCellComponent: Component, Codable {
    public var cellID: Int?
    public var hitCount: Int = 0
    public static let requiredHits = 18
    
    public init(cellID: Int? = nil) {
        self.cellID = cellID
    }
}
