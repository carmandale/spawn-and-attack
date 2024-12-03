import SwiftUI

struct LoadingView: View {
    @Environment(AppModel.self) private var appModel: AppModel

    var body: some View {
        VStack {
            Text("Loading Assets...")
                .font(.title)
                .padding()

            ProgressView()
                .progressViewStyle(.circular)
                .padding()
                
            Text("Please wait while we prepare your experience...")
                .foregroundStyle(.secondary)
                .padding()
        }

    }
}
