# Attack Cancer Game - Implementation Plan

## Overview
A visionOS immersive game where players target and destroy cancer cells using ADCs (Antibody-Drug Conjugates) in 3D space.

## Core Components

### 1. Views Structure
- `AttackCancerView.swift` - Main RealityView container
  - Manages scene setup
  - Handles cell spawning
  - Coordinates attachments
  - Manages game state
- `HitCounterView.swift` - SwiftUI view for cell hit tracking
  - Displays hit progress (0/18)
  - Visual feedback for hits
  - Attached to individual cancer cells

### 2. Game State Management
```swift
@Observable class AppModel {
    // Game State
    var immersiveSpaceState: ImmersiveSpaceState
    var score: Int
    var totalHits: Int
    var cellsDestroyed: Int
    
    // Cell Management
    var maxCancerCells: Int
    var cancerCells: [Entity]
    private var nextCellID: Int
    
    // Spawn Configuration
    var spawnBounds: BoundingBox
}
```

### 3. Components
```swift
// Cancer Cell Component
struct CancerCellComponent: Component {
    var cellID: Int
    var hitCount: Int
    static let requiredHits = 18
}

// Movement Component
struct MovementComponent: Component {
    var speed: Float
    var rotationAxis: SIMD3<Float>
    var time: TimeInterval
}
```

### 4. Systems
- `CancerCellSystem`
  - Tracks hits
  - Manages cell destruction
  - Updates game state
- `MovementSystem`
  - Handles cell animation
  - Updates positions
  - Manages spatial relationships

## Implementation Flow

1. Initial Setup
   - Create new view files
   - Set up AppModel
   - Configure basic RealityView

2. Cell Management
   - Implement cell spawning
   - Add movement system
   - Setup hit detection

3. UI Integration
   - Create HitCounterView
   - Implement attachments
   - Add visual feedback

4. Game Logic
   - Track hits per cell
   - Handle cell destruction
   - Update score system

## Technical Details

### Cell Spawning
```swift
func spawnCancerCell(content: RealityViewContent, 
                     attachments: AttachmentsProvider) async throws -> Entity {
    let cell = Entity()
    let cellID = appModel.getNextCellID()
    
    // Add components
    cell.components[CancerCellComponent.self] = CancerCellComponent(cellID: cellID)
    cell.components[MovementComponent.self] = MovementComponent(...)
    
    // Position randomly within bounds
    cell.position = randomPosition(within: appModel.spawnBounds)
    
    appModel.registerCancerCell(cell)
    return cell
}
```

### Attachment System
```swift
RealityView { content, attachments in
    // Initial setup
} update: { content, attachments in
    // Update attachments
} attachments: {
    ForEach(appModel.cancerCells) { cell in
        Attachment(id: "progress-\(cell.cellID)") {
            HitCounterView(hits: cell.hitCount)
        }
    }
}
```

## Migration Strategy
1. Keep existing files untouched
2. Create new implementation in parallel
3. Test new system independently
4. Switch over in SpawnAndAttrackApp.swift when ready

## Next Steps
1. Create HitCounterView.swift
2. Create AttackCancerView.swift
3. Update SpawnAndAttrackApp.swift
4. Implement basic cell spawning
5. Add hit counter attachments
6. Test and refine

Would you like me to proceed with implementing any of these components?
