import SwiftUI
import RealityKit

struct ADCVolumetricView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var adcEntity: Entity?
    
    var body: some View {
        RealityView { content in
            if let cachedADC = appModel.assetLoadingManager.entityTemplates["adc"] {
                let adcInstance = cachedADC.clone(recursive: true)
                self.adcEntity = adcInstance
                content.add(adcInstance)
            }
        }
        .gesture(
            DragGesture()
                .targetedToEntity(adcEntity ?? Entity())
                .handActivationBehavior(.pinch)
        )
        .onChange(of: appModel.labSpaceActive) { newValue in 
            if !newValue {
                dismissWindow(id: "ADCVolumetric")
            }
        }
    }
}
