//
//  UIStabilizerSystem.swift
//  RealityKitContent
//
//  Created by Dale Carman on 11/29/24.
//

import RealityKit

/// System that maintains UI elements at a fixed offset from their target entities
@MainActor
public class UIStabilizerSystem: System {
    /// Query for entities with UIStabilizer component
    static let query = EntityQuery(where: .has(UIAttachmentComponent.self))
    
    /// Initialize the system with the RealityKit scene
    public required init(scene: Scene) { }
    
    /// Update UI elements with stabilizer component
    public func update(context: SceneUpdateContext) {
        let cellQuery = EntityQuery(where: .has(CancerCellComponent.self))
        let cells = context.scene.performQuery(cellQuery)
        
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let attachment = entity.components[UIAttachmentComponent.self] else { continue }
            
            // Find target cell by CancerCellComponent's cellID
            guard let targetCell = cells.first(where: { entity in
                entity.components[CancerCellComponent.self]?.cellID == attachment.attachmentID
            }) else { continue }
            
            // Get target's world position and apply offset
            let targetPos = targetCell.position(relativeTo: nil)
            entity.setPosition(targetPos + attachment.offset, relativeTo: nil)
        }
    }
}
