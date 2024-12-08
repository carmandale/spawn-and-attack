# SpawnAndAttrack Refactoring Checklist

## 1. Trace Dependencies First
- [x] Map out component dependencies
  - AppModel -> CancerCellSystem, ADCMovementSystem
  - ViewModel -> AppModel, AssetLoadingManager
  - Views -> ViewModel
- [x] Identify all code references and usages
  - Game state management through AppModel
  - UI state coordination via ViewModel
  - Asset loading through AssetLoadingManager
- [x] Document dependency chains between systems
  - View -> ViewModel -> AppModel (Unidirectional flow)
  - AssetLoadingManager shared across components

## 2. Incremental Changes
- [x] Break changes into smaller, manageable units
  - State management improvements
  - Property observers implementation
  - ViewModel intermediary role
- [x] Verify each change with tests before proceeding
- [x] Maintain existing functionality while implementing new architecture

## 3. Document Critical Components
- [x] Create inventory of core gameplay components
  - CancerCellSystem
  - ADCMovementSystem
  - AssetLoadingManager
- [x] Add documentation for essential code sections
    - Include "why" explanations in comments
- [x] Identify and mark critical game state management code

## 4. Pre-Removal Review
- [x] Component Usage Check
    - Is this component actively used in game mechanics?
    - What systems depend on this component?
- [x] Impact Analysis
    - Will removal break any existing functionality?
    - Is game state management preserved?

## Code Review and Verification

### AppModel.swift - Game State Components

- [x] **Apply `@Observable` to `AppModel` class**
  
  ```swift:AppModel.swift
  @Observable
  final class AppModel {
      var gamePhase: GamePhase = .gamePlay
      // ... existing code ...
  }
  ```
  
- [x] **Use property observers to react to state changes**
  - Implement `didSet` observers where appropriate to handle side effects.

- [x] **Separate concerns between game logic and presentation**
  - Ensure `AppModel` contains only game logic and state, without UI code.

- [x] Cancer Cell Management
  - [x] `cancerCells` array
  - [x] Cell registration/removal methods
  - [x] Cell update notification handling
  - [x] Collision handling
  - [x] Spawn configuration

- [x] Game State Management
  - [x] Game phase handling
  - [x] Score tracking
  - [x] Hit counting
  - [x] Game systems (`CancerCellSystem`, `ADCMovementSystem`)

- [x] Asset Management
  - [x] Asset loading coordination
  - [x] Asset state tracking

### ViewModel.swift - UI Components

- [x] **Ensure `ViewModel` handles presentation logic and user interactions**
  - Separate presentation concerns from `AppModel`.

- [x] View State Management
  - [x] Navigation path handling
  - [x] View state transitions
  - [x] Loading states

- [x] Immersive Space Management
  - [x] Space state handling
  - [x] Space transitions
  - [x] Coordination with `AppModel`

### Integration Points

- [x] **Maintain unidirectional data flow**
  - Ensure data flows from `Model` → `ViewModel` → `View`.

- [x] AppModel → ViewModel Communication
  - [x] Game state updates
  - [x] Score updates
  - [x] Asset loading coordination

- [x] ViewModel → AppModel Communication
  - [x] Game phase transitions
  - [x] Space state changes

## Best Practices Implementation

1. [x] **Single source of truth for game state**
   - Confirm that `AppModel` is the authoritative source.

2. [x] **Use property observers to react to state changes**
   - Leverage `didSet` to handle updates and trigger side effects.
   
   ```swift
   var isPlaying = false {
       didSet {
           if isPlaying {
               startGame()
           } else {
               pauseGame()
           }
       }
   }
   ```

3. [x] **Utilize environment objects judiciously**
   - Share only essential state through environment objects.

4. [x] **Separate concerns between game logic and presentation**
   - Keep models focused on data and logic.
   - Ensure ViewModels handle presentation and user interaction.

## Common Pitfalls to Avoid

- [ ] **Mixing game logic with presentation**
  - Verify that models do not contain any UI code.

- [ ] **Inconsistent state management**
  - Ensure all state changes are predictable and managed through defined pathways.

- [ ] **Tight coupling between layers**
  - Avoid direct references from Views to Models; use ViewModels as intermediaries.

- [ ] **Overcomplicating ViewModels**
  - Keep ViewModels focused and avoid adding excessive logic.

## Next Steps

1. **IntroView Integration**
   - [ ] Integrate `UIPortalView` for the introductory experience.
   - [ ] Set up transitions between views.

2. **Placeholder Views**
   - [ ] Implement 2D welcome screen.
   - [ ] Create ADC Builder window.
   - [ ] Develop ADC Viewer window.

3. **SpawnAndAttrackApp.swift Update**
   - [x] Control application flow using ViewModel
   - [x] Ensure proper initialization
   - [x] Set up the view hierarchy
   - [x] Configure immersive spaces
   - [x] Implement proper environment injection

4. **Final Integration Steps**
   - [x] Verify all components are properly connected
   - [x] Test state propagation through MVVM chain
   - [x] Ensure proper cleanup and resource management
   - [x] Document architecture decisions