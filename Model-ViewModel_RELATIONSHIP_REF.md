# Model-ViewModel Communication Patterns in visionOS Reference Projects

## Overview
This document analyzes Model-ViewModel communication patterns and immersive space management across three reference projects: Spaceship, HappyBeam, and SwiftSplash.

## Common Patterns

### State Management
- Use `@Observable` for model classes to enable automatic view updates when the model changes.

  ```swift
  @Observable
  class GameModel {
      var gameState: GameState
      // Other properties...
  }
  ```

- Share app state through environment objects when necessary.

### Communication Flow
- **Models** own core game logic and state
- **ViewModels** handle presentation logic and user interactions
- Maintain a **unidirectional data flow** from Model → ViewModel → View

### Immersive Space Management
- **Centralized space coordination** using a single source of truth for entities
- **Clear lifecycle management** with proper initialization and cleanup
- **Consistent state transitions** to manage different phases and immersive styles

## Project-Specific Implementations

### Spaceship
- Game state managed through `AppModel`
- Phase-based navigation using `GamePhase` enum
- Clear separation between game systems and presentation

### HappyBeam
- Gesture and input handling in dedicated models (`HeartGestureModel`)
- Multiplayer state synchronization
- Entity management through global coordinators

### SwiftSplash
- Material-based gameplay systems
- Audio-visual feedback coordination
- Physics and collision management

## Best Practices
1. **Single source of truth for game state**
2. **Use property observers** to react to state changes and trigger necessary updates in the immersive space
3. **Utilize environment objects judiciously** to share essential state
4. **Separate concerns between game logic and presentation**

## Implementation Guidelines
1. **Use `@Observable` for model classes**
2. **Implement clear state transitions**
3. **Centralize space management**
4. **Handle lifecycle events consistently**
5. **Separate concerns between game logic and presentation**

## Common Pitfalls
1. **Mixing game logic with presentation**
2. **Inconsistent state management**
3. **Tight coupling between layers**
4. **Overcomplicating ViewModels**

## Recommended Architecture

swift
// Core game state
@Observable class GameModel {
var gameState: GameState
var spaceState: SpaceState
}
// Presentation logic
@Observable class ViewModel {
let model: GameModel
var presentationState: ViewState
}


## Communication Patterns
1. Model → ViewModel: State updates
2. ViewModel → Model: User actions
3. ViewModel → View: Presentation updates
4. View → ViewModel: User input

## Space Management
1. Centralized coordination
2. Clear ownership
3. Consistent lifecycle
4. State-driven transitions