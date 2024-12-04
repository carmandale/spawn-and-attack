onChange(of:perform:)
Adds an action to perform when the given value changes.
iOS 14.0–17.0
Deprecated
iPadOS 14.0–17.0
Deprecated
Mac Catalyst 14.0–17.0
Deprecated
macOS 11.0–14.0
Deprecated
tvOS 14.0–17.0
Deprecated
visionOS 1.0–1.0
Deprecated
watchOS 7.0–10.0
Deprecated
nonisolated
func onChange<V>(
    of value: V,
    perform action: @escaping (V) -> Void
) -> some Scene where V : Equatable
Deprecated
Use onChange(of:initial:_:) or onChange(of:initial:_:) instead. The trailing closure in each case takes either zero or two input parameters, compared to this method which takes one.
Be aware that the replacements have slightly different behvavior. This modifier’s closure captures values that represent the state before the change. The new modifiers capture values that correspond to the new state. The new behavior makes it easier to perform updates that rely on values other than the one that caused the modifier’s closure to run.
Parameters
value
The value to check when determining whether to run the closure. The value must conform to the Equatable protocol.
action
A closure to run when the value changes. The closure provides a single newValue parameter that indicates the changed value.
Return Value
A scene that triggers an action in response to a change.
Discussion
Use this modifier to trigger a side effect when a value changes, like the value associated with an Environment value or a Binding. For example, you can clear a cache when you notice that a scene moves to the background:
struct MyScene: Scene {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var cache = DataCache()


    var body: some Scene {
        WindowGroup {
            MyRootView()
        }
        .onChange(of: scenePhase) { newScenePhase in
            if newScenePhase == .background {
                cache.empty()
            }
        }
    }
}
The system may call the action closure on the main actor, so avoid long-running tasks in the closure. If you need to perform such tasks, detach an asynchronous background task:
.onChange(of: scenePhase) { newScenePhase in
    if newScenePhase == .background {
        Task.detached(priority: .background) {
            // ...
        }
    }
}
The system passes the new value into the closure. If you need the old value, capture it in the closure.


NEW VERSION

Instance Method
onChange(of:initial:_:)
Adds an action to perform when the given value changes.
iOS 17.0+
iPadOS 17.0+
Mac Catalyst 17.0+
macOS 14.0+
tvOS 17.0+
visionOS 1.0+
watchOS 10.0+
nonisolated
func onChange<V>(
    of value: V,
    initial: Bool = false,
    _ action: @escaping () -> Void
) -> some Scene where V : Equatable
Show all declarations
Parameters
value
The value to check when determining whether to run the closure. The value must conform to the Equatable protocol.
initial
Whether the action should be run when this scene initially appears.
action
A closure to run when the value changes.
Return Value
A scene that triggers an action in response to a change.
Discussion
Use this modifier to trigger a side effect when a value changes, like the value associated with an Environment key or a Binding. For example, you can clear a cache when you notice that a scene moves to the background:
struct MyScene: Scene {
    @Environment(\.locale) private var locale
    @StateObject private var cache = LocalizationDataCache()


    var body: some Scene {
        WindowGroup {
            MyRootView(cache: cache)
        }
        .onChange(of: locale) {
            cache.empty()
        }
    }
}
The system may call the action closure on the main actor, so avoid long-running tasks in the closure. If you need to perform such tasks, detach an asynchronous background task:
.onChange(of: locale) {
    Task.detached(priority: .background) {
        // ...
    }
}
When the value changes, the new version of the closure will be called, so any captured values will have their values from the time that the observed value has its new value.
