# File Reference Map

## 1. View Layer
```
Our Files:                    Reference Equivalent:
AttackCancerView.swift ✓     ImmersiveView.swift (Spaceship)
- Main game view              - Main game view for different phases
```

## 2. ViewModel Layer
```
Our Files:                    Reference Equivalent:
AttackCancerViewModel.swift ✗ ImmersiveViewModel.swift (Spaceship)
- Need to create             - Handles game state & collisions
```

## 3. Components
```
Our Files:                    Reference Equivalent:
ADCComponent.swift ✓         ShipControlComponent.swift (Spaceship)
MovementComponent.swift ✓     ThrottleComponent.swift (Spaceship)
CancerCellComponent.swift ✓   PlanetComponent.swift (Spaceship)
AttachmentComponent.swift ✓   ConnectableComponent.swift (SwiftSplash)
```

## 4. Systems
```
Our Files:                    Reference Equivalent:
ADCMovementSystem.swift ✓    ShipFlightSystem.swift (Spaceship)
ADCSystem.swift ✓           ShipControlSystem.swift (Spaceship)
CancerCellSystem.swift ✓    PlanetVisualsSystem.swift (Spaceship)
```

## 5. State Management
```
Our Files:                    Reference Equivalent:
AppModel.swift ✓            AppModel.swift (Spaceship)
GameEvents.swift ✓          AppState+Phases.swift (SwiftSplash)
```
