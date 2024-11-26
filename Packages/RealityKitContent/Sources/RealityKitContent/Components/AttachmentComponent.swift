import RealityKit

@MainActor
public struct AttachmentComponent: Component, Codable {
    public var cellID: Int
    public var attachmentID: String
    public var hitCount: Int
    
    public init(cellID: Int, attachmentID: String, hitCount: Int = 0) {
        self.cellID = cellID
        self.attachmentID = attachmentID
        self.hitCount = hitCount
    }
}
