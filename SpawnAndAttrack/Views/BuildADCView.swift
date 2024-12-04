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
            WindowToggle(
                window: .adcVolumetric,
                isShowing: .init(
                    get: { appModel.isShowingADCVolumetric },
                    set: { appModel.isShowingADCVolumetric = $0 }
                ),
                label: "View in 3D"
            )
            .padding(.vertical)

            // Build Button
            Button(action: {
                Task {
                    print("Building ADC with Color: \(selectedColor), Material: \(selectedMaterial)")
                    // Close lab space and windows
                    if appModel.labSpaceActive {
                        await dismissImmersiveSpace()
                        appModel.labSpaceActive = false
                    }
                    if appModel.isShowingADCVolumetric {
                        dismissWindow(id: AppModel.WindowState.adcVolumetric.windowId)
                        appModel.isShowingADCVolumetric = false
                    }
                    dismissWindow(id: AppModel.WindowState.adcBuilder.windowId)
                    appModel.isShowingADCBuilder = false
                    
                    // Open attack space
                    await openImmersiveSpace(id: AppModel.SpaceState.attack.spaceId)
                    appModel.attackSpaceActive = true
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
        .padding()
        .onChange(of: appModel.labSpaceActive) {
            if !appModel.labSpaceActive {
                dismissWindow(id: "ADCBuilder")
            }
        }
    }
}
