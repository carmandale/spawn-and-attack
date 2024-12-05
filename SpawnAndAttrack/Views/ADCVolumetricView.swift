import SwiftUI
import RealityKit

struct ADCVolumetricView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var adcEntity: Entity?
    
    static let defaultSize: CGFloat = 0.5
    
    var body: some View {
        
        RealityView { content in
            if let cachedADC = appModel.assetLoadingManager.entityTemplates["adc"] {
                let adcInstance = cachedADC.clone(recursive: true)
                self.adcEntity = adcInstance
                adcInstance.scale = .init(x: 2.0, y: 2.0, z: 2.0)
                content.add(adcInstance)
            } 
        }
        
        .onChange(of: appModel.labSpaceActive, initial: true) {
            if !appModel.labSpaceActive {
                dismissWindow(id: AppModel.WindowState.adcVolumetric.windowId)
            }
        }
    }
}
