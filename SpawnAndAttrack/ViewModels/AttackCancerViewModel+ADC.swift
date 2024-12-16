import SwiftUI
import RealityKit
import RealityKitContent

extension AttackCancerViewModel {
    func spawnADC(from position: SIMD3<Float>, targetPoint: Entity, forCellID cellID: Int) async {
        guard let template = adcTemplate,
              let root = rootEntity else {
            print("❌ ADC #\(successfulADCLaunches + 1) Failed - Missing template or root")
            return
        }
        
        successfulADCLaunches += 1
        print("✅ ADC #\(successfulADCLaunches) Launched (Total Taps: \(totalTaps))")
        
        // Set the flag for first ADC fired
        if !appModel.gameState.hasFirstADCBeenFired {
            appModel.gameState.hasFirstADCBeenFired = true
        }
        
        // Increment ADC count
        appModel.gameState.incrementADCsDeployed()
        
        // Clone the template
        let adc = template.clone(recursive: true)
        
        // Update ADCComponent properties
        guard var adcComponent = adc.components[ADCComponent.self] else { return }
        adcComponent.targetCellID = cellID
        adcComponent.startWorldPosition = position  // Use the hand position
        adc.components[ADCComponent.self] = adcComponent
        
        // Set initial position
        adc.position = position
        
        // Add to scene
        root.addChild(adc)
        
        // Start movement
        ADCMovementSystem.startMovement(entity: adc, from: position, to: targetPoint)
    }
} 