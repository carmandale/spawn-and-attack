import RealityKit
import Foundation

@MainActor
extension ADCMovementSystem {
    static func resetADC(entity: Entity, component: inout ADCComponent) {
        // Reset ADC state
        component.state = .idle
        component.targetEntityID = nil
        component.targetCellID = nil
        component.movementProgress = 0
        
        // Stop any ongoing animations/audio
        entity.stopAllAnimations()
        entity.stopAllAudio()
    }
}
