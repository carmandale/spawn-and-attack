import SwiftUI

struct WindowToggle: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    let window: AppModel.WindowState
    @Binding var isShowing: Bool
    let label: String
    
    var body: some View {
        Button(label) {
            isShowing.toggle()
            if isShowing {
                openWindow(id: window.windowId)
            } else {
                dismissWindow(id: window.windowId)
            }
        }
        .buttonStyle(.bordered)
    }
}
