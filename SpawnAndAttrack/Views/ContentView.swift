import SwiftUI
import RealityKit

struct ContentView: View {
    @Environment(AppModel.self) private var appModel: AppModel

    var body: some View {
        VStack(spacing: 20) {
            
            
            ToggleImmersiveSpaceButton(spaceID: .attackCancer)
                .padding()
            
            ToggleImmersiveSpaceButton(spaceID: .lab)
                .padding()
        }
    }
}

