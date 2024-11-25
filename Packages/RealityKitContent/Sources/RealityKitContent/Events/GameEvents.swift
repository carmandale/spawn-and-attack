import RealityKit

/// Events related to ADC hits and cancer cell state changes
public enum GameEvents {
    /// Event triggered when an ADC hits a cancer cell
    public struct ADCHit: RealityKit.Event {
        public let adc: Entity
        public let cell: Entity
        
        public init(adc: Entity, cell: Entity) {
            self.adc = adc
            self.cell = cell
        }
    }
    
    /// Event triggered when an ADC completes its path
    public struct ADCPathCompleted: RealityKit.Event {
        public let adc: Entity
        public let attachmentPoint: Entity
        
        public init(adc: Entity, attachmentPoint: Entity) {
            self.adc = adc
            self.attachmentPoint = attachmentPoint
        }
    }
}
