//
//  AppModel+Collisions.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 12/10/24.
//

import RealityKit
import RealityKitContent
import SwiftUI

extension GameState {
    // MARK: - Collision Handling

        
        func handleCollisionBegan(_ collision: CollisionEvents.Began) {
            guard shouldHandleCollision(collision) else { return }
            
            // Check for head-microscope collision - only play sound, no transition
            if hasHeadCollision(collision) && hasMicroscopeCollision(collision) {
                print("Head collision with microscope detected")
                Task {
                    await appModel.transitionToPhase(.building)
                }
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
            if let _ = entities.itemA.components[CancerCellComponent.self],
               let _ = entities.itemB.components[CancerCellComponent.self] {
                // print("\nCell-to-cell collision detected")
                // print("Cell A ID: \(cellA.cellID ?? -1)")
                // print("Cell B ID: \(cellB.cellID ?? -1)")
                
                if let _ = entities.itemA.components[PhysicsMotionComponent.self],
                   let _ = entities.itemB.components[PhysicsMotionComponent.self] {
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
        
        private func hasHeadCollision(_ collision: CollisionEvents.Began) -> Bool {
            let entityA = collision.entityA
            let entityB = collision.entityB
            
            // print("\n=== Head Collision Details ===")
            // Entity A details
            // print("Entity A Name: \(entityA.name)")
            // print("Entity A World Position: \(entityA.position(relativeTo: nil))")  // World position
            // print("Entity A Local Position: \(entityA.position)")  // Local position
            // print("Entity A Components: \(entityA.components)")
            // print("Entity A Collision Group: \(String(describing: entityA.components[CollisionComponent.self]?.filter.group))")
            
            // Entity B details
            // print("Entity B Name: \(entityB.name)")
            // print("Entity B World Position: \(entityB.position(relativeTo: nil))")  // World position
            // print("Entity B Local Position: \(entityB.position)")  // Local position
            // print("Entity B Components: \(entityB.components)")
            // print("Entity B Collision Group: \(String(describing: entityB.components[CollisionComponent.self]?.filter.group))")
            
            // print("Contact World Position: \(collision.position)")
            
            let hasCollision = entityA.components[CollisionComponent.self]?.filter.group == .default ||
                              entityB.components[CollisionComponent.self]?.filter.group == .default
            
            if hasCollision {
                // Look for MicroscopeViewer parent which has the AudioLibraryComponent
                if let microscopeEntity = [entityA, entityB]
                    .first(where: { $0.name == "MicroscopeReferenceSphere" })?
                    .parent {  // Get the parent MicroscopeViewer which has the audio
                    microscopeEntity.stopAllAudio()
    //                if let audioComponent = microscopeEntity.components[AudioLibraryComponent.self],
    //                   let attachSound = audioComponent.resources["Sonic_Pulse_Hit_01.wav"] {
    //                    microscopeEntity.playAudio(attachSound)
    //                }
                }
            }
            
            return hasCollision
        }

        private func hasMicroscopeCollision(_ collision: CollisionEvents.Began) -> Bool {
            let entityA = collision.entityA
            let entityB = collision.entityB
            
            let hasA = entityA.components[MicroscopeViewerComponent.self] != nil
            let hasB = entityB.components[MicroscopeViewerComponent.self] != nil
            let hasCollision = hasA || hasB
            
            // print("  Has MicroscopeViewer component:")
            // print("    Entity A: \(hasA)")
            // print("    Entity B: \(hasB)")
            
            return hasCollision
        }

}
