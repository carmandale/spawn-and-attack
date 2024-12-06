import SwiftUI
import RealityKit

struct BuildADCView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var selectedSegment = 0
    @State private var selectedColor = ""
    @State private var selectedMaterial = ""

    var body: some View {
        VStack(spacing: 20) {
            // Large Title
            Text("Build Your ADC")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top)

            // Segmented Control
            Picker("Select Part", selection: $selectedSegment) {
                Text("Antibody").tag(0)
                Text("Linker").tag(1)
                Text("Payload").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // Color Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Color")
                    .font(.headline)
                HStack {
                    ForEach(["Red", "Green", "Blue"], id: \.self) { color in
                        Circle()
                            .fill(Color(color.lowercased()))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.black : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                    }
                }
            }
            .padding(.horizontal)

            // Material Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Material")
                    .font(.headline)
                HStack {
                    ForEach(["Metal", "Plastic", "Glass"], id: \.self) { material in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 40)
                            .overlay(
                                Text(material)
                                    .font(.footnote)
                                    .foregroundColor(.black)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedMaterial == material ? Color.black : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedMaterial = material
                            }
                    }
                }
            }
            .padding(.horizontal)

            // View in 3D Button
            Button(action: {
                if appModel.isShowingADCVolumetric {
                    dismissWindow(id: AppModel.WindowState.adcVolumetric.windowId)
                } else {
                    openWindow(id: AppModel.WindowState.adcVolumetric.windowId)
                }
                appModel.isShowingADCVolumetric.toggle()
            }) {
                Text("View in 3D")
                    .foregroundColor(appModel.isShowingADCVolumetric ? .blue : .primary)
            }
            .padding(.vertical)

            // Build Button
            Button(action: {
                Task {
                    print("Building ADC with Color: \(selectedColor), Material: \(selectedMaterial)")
                    // Use AppModel's phase transition instead of directly managing spaces
                    appModel.startAttackPhase()
                }
            }) {
                Text("Build")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .frame(width: 200, height: 400)
        .padding()
        .onChange(of: appModel.labSpaceActive) {
            if !appModel.labSpaceActive {
                dismissWindow(id: "ADCBuilder")
            }
        }
    }
}
