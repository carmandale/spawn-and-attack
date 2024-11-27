# Reference Project Analysis

## Spaceship Game ✅ Verified

### Components
1. Core Components:
- `ThrottleComponent`: Manages spaceship throttle (0-1 range)
- `PlanetComponent`: Handles planet states including radius and visit status
- `AsteroidComponent`: Marks asteroid entities
- `ClosureComponent`: Executes closures during system updates
- `ShipControlComponent`: Manages spaceship control parameters
- `AudioMaterialLookupComponent`: Handles audio materials for entities

2. View Components:
- `HangarView`: Interactive view for spaceship customization
- `ImmersiveView`: Main game view for different phases
- `MenuView`: UI for switching between scenes and phases
- `SpaceshipView`: Handles spaceship visualization and interaction

### Systems
1. Control Systems:
- `ShipControlSystem`: Manages spaceship control parameters
- `HandsShipControlProviderSystem`: Handles hand tracking for controls
- `ClosureSystem`: Executes component closures during updates

2. Game Systems:
- `ShipFlightSystem`: Manages spaceship flight mechanics
- `SceneReconstruction`: Handles AR scene reconstruction and mesh updates

### State Management
1. Game State (`AppModel`):
- Game phases (joyRide, work)
- UI states (hangar, flight school, immersive space)
- Audio mixer settings
- Surroundings state
- Transition states

2. Control State (`ShipControlParameters`):
- Throttle
- Pitch
- Roll
- Reset functionality

3. View Models:
- `HangarViewModel`: Manages hangar view state and spaceship preparation
- `ImmersiveViewModel`: Handles immersive view state including:
  - Audio state
  - Game level
  - Entity management
  - Scene transitions

4. Audio State (`AudioMixerStorage`):
- Music channel
- Spaceship sounds
- Planet sounds
- Collision sounds

### Architecture Notes
- Uses RealityKit's ECS (Entity Component System) pattern
- Clear separation between visual components, game logic, and state management
- Multi-platform support (iOS and visionOS)
- Platform-specific features (AR world tracking, hand tracking)

## BOTAnist ✅ Verified

### Components
1. Core Components:
- `PlantComponent`: Marks entities as plants with type and interaction state
- `JointPinComponent`: Connects static meshes to rigged entity joints
- `RobotComponent`: Manages robot characteristics and state

2. Robot Parts:
- `RobotData`: Structure containing robot configuration data
- `RobotCharacter`: Main robot entity with animation and movement control
- `BodyType`: Enum defining robot movement types (bipedal, wheeled, hovering)

### Systems
1. Animation Systems:
- `PlantAnimationProvider`: Manages plant growth and celebration animations
- `JointPinSystem`: Maintains connections between static meshes and joints

2. Control Systems:
- Touch controls for iOS
- Hand tracking for visionOS
- Platform-specific gesture handling

### State Management
1. App State:
- `AppState`: Central state management with phases:
  - waitingToStart
  - loadingAssets
  - playing
  - exploration

2. Robot State:
- Customization options:
  - Part materials
  - Light colors
  - Mesh types
  - Face configurations
- Movement state
- Animation state

3. Environment State:
- Plant interaction tracking
- Scene reconstruction
- Camera positioning
- Environment scaling

### Views
1. Main Views:
- `ContentView`: Root view managing app phases
- `RobotCustomizationView`: Robot configuration interface
- `ExplorationView`: Main gameplay view
- `OrnamentView`: UI overlays and scoring

2. Supporting Views:
- `StartScreenView`: Loading screen
- `RobotView`: Robot visualization
- `StartPlantingButtonView`: Game initiation

### Architecture Notes
- Built for visionOS and iOS/macOS
- Uses SwiftUI for UI components
- RealityKit for 3D content
- Volumetric window support for visionOS
- Asset management through separate package (BOTanistAssets)
- Clear separation between robot customization and gameplay phases

## Diorama ✅ Verified

### Components
1. Core Components:
- `PointOfInterestComponent`: Marks entities as interactive points on the map
- `TrailComponent`: Defines animated trail paths on the terrain
- `RegionSpecificComponent`: Manages region-specific behaviors
- `ControlledOpacityComponent`: Controls entity visibility
- `FlockingComponent`: Manages bird flocking behavior

2. Runtime Components:
- `PointOfInterestRuntimeComponent`: Runtime state for points of interest
- `BillboardComponent`: Makes entities face the camera

### Systems
1. Animation Systems:
- `TrailAnimationSystem`: Animates trail paths on terrain
- `FlockingSystem`: Controls bird flocking behavior
- `BillboardSystem`: Manages camera-facing entities

2. View Management:
- `AttachmentsProvider`: Maintains view attachments
- Region-based opacity control
- Terrain morphing system

### State Management
1. App State (`ViewModel`):
- Root entity management
- Immersive content visibility
- Terrain morphing progress
- Content scale control
- Audio state management

2. Region Management:
- Two main regions: Yosemite and Catalina
- Region-specific opacity control
- Region-specific audio management
- Smooth transitions between regions

### Views
1. Main Views:
- `ContentView`: Main window with controls
- `DioramaView`: Immersive 3D content
- `LearnMoreView`: Point of interest details

2. UI Components:
- Region transition slider
- Scale control
- Information overlays
- Glass background effects

### Architecture Notes
- Built for visionOS
- Uses RealityKit and Reality Composer Pro
- Volumetric window support
- Separate package for 3D content (RealityKitContent)
- Interactive terrain morphing
- Ambient audio system
- Bird animation system
- Responsive UI scaling

## HappyBeam ✅ Verified

### Components
1. Core Components:
- `GameModel`: Central state management for game state and gameplay
- `HeartGestureModel`: Handles hand tracking and gesture recognition
- `ProjectionSessionInfo`: Manages multiplayer session state
- `BeamCollisions`: Handles beam and cloud collision logic
- `Player`: Manages player state and scoring

2. Runtime Components:
- `CollisionEvents`: Handles beam and cloud collisions
- `AccessibilityEvents`: Manages activation events
- `GroupSession`: Manages SharePlay multiplayer sessions
- `AudioPlaybackController`: Controls game audio

### Systems
1. Game Systems:
- `BeamCollisions`: Manages beam-cloud interaction logic
- `CloudSpawning`: Controls cloud generation and placement
- `ScoreSystem`: Tracks player progress
- `AudioSystem`: Manages game music and effects
- `HeartGestureSystem`: Detects and processes hand gestures

2. Multiplayer Systems:
- `GroupSession`: Handles SharePlay integration
- `GroupSessionMessenger`: Manages multiplayer communication
- `BeamMessage`: Synchronizes beam positions
- `ScoreMessage`: Synchronizes scoring events

### State Management
1. Game State:
- Centralized `GameModel` using `@Observable`
- Game phases (menu, solo play, multiplayer)
- Score tracking
- Cloud state tracking
- Audio state
- Pause/resume functionality

2. Multiplayer State:
- SharePlay session management
- Player synchronization
- Score synchronization
- Cloud state synchronization
- Beam position synchronization

### Views
1. Main Views:
- `HappyBeam`: Root view and navigation
- `HappyBeamSpace`: Immersive game environment
- `Start`: Menu and game mode selection
- `SoloPlay`: Single player mode
- `MultiPlay`: Multiplayer mode

2. UI Components:
- Glass background effects
- Score display
- Player status indicators
- Game controls
- Multiplayer status

### Architecture Notes
- Built for visionOS
- Uses RealityKit and SwiftUI
- SharePlay integration
- Hand tracking and gesture recognition
- Entity Component System (ECS)
- Asset management through separate package
- Clear separation between game logic and presentation
- Spatial audio integration
- Volumetric window support

## HelloWorld ✅ Verified

### Components
1. Core Components:
- `RotationComponent`: Simple component for entity rotation with speed and axis
- `TraceComponent`: Manages trail rendering behind moving entities
- `SunPositionComponent`: Controls sun position relative to earth

2. Runtime Components:
- Built-in RealityKit components for models and transforms
- Efficient use of ModelComponent for mesh rendering
- UnlitMaterial for optimized rendering

### Systems
1. Core Systems:
- `RotationSystem`: Handles entity rotation updates
- `TraceSystem`: Generates and updates trail meshes
- `SunPositionSystem`: Updates sun position and lighting

2. View Management:
- Clean separation of window, volume, and immersive spaces
- Efficient RealityView usage
- SwiftUI integration with RealityKit

### State Management
1. App State:
- Centralized `ViewModel` using @Observable
- Clear navigation path management
- Immersion style control

2. Entity State:
- Direct component state updates
- Efficient system queries
- Proper component registration

### Views
1. Main Views:
- `TableOfContents`: Main navigation hub
- `ModuleDetail`: Content presentation
- `RealityView` wrappers for 3D content

2. UI Components:
- Custom alignment guides
- Typed text animations
- Responsive layouts

### Architecture Notes
- Built for visionOS
- Minimal custom components
- Leverages built-in RealityKit systems
- Clean separation of 2D and 3D content
- Efficient use of RealityKit resources
- Example of proper component registration
- Demonstrates all three space types (window, volume, immersive)

## SwiftSplash ✅ Verified

### Components
1. Core Components:
- `AppState`: Central state management using @Observable
- `ConnectableComponent`: Manages track piece connections
- `RideWaterComponent`: Controls water flow animations
- `HoverEffectComponent`: Handles piece hover effects
- `ModelSortGroupComponent`: Manages transparent object rendering

2. Runtime Components:
- `ARKitSession`: Manages AR session and world tracking
- `WorldTrackingProvider`: Provides device location and orientation
- `AudioPlaybackController`: Controls game audio
- `ViewAttachmentEntity`: Manages UI attachments in 3D space

### Systems
1. Game Systems:
- `PieceManagement`: Handles track piece placement and connections
- `TrackUpdates`: Controls track state and animations
- `MaterialSystem`: Manages track piece materials and appearances
- `SoundEffectPlayer`: Controls game audio and effects

2. AR Systems:
- `WorldTracking`: Manages AR session and device tracking
- `TransparencySystem`: Controls rendering order of transparent objects
- `AttachmentSystem`: Manages UI elements in AR space

### State Management
1. Game State:
- Centralized `AppState` using `@Observable`
- Track piece connections and relationships
- Material selection and management
- Audio state (music modes, volume)
- Game phase tracking

2. Track State:
- Track piece connections
- Piece selection and editing
- Water flow animations
- Track validation

### Views
1. Main Views:
- `ContentView`: Main game interface
- `TrackBuildingView`: Track construction interface
- `PlaceStartPieceView`: Initial piece placement
- `PieceShelfTrackButtonsView`: Track piece selection

2. UI Components:
- Glass background effects
- Track piece buttons
- Material selection
- Game controls
- AR placement guides

### Architecture Notes
- Built for visionOS and iOS
- Uses RealityKit and SwiftUI
- ARKit integration
- Entity Component System (ECS)
- Modular track piece system
- Advanced material management
- Spatial audio integration
- Transparent object sorting
- Clear separation of concerns
