//
//  ImmersiveView.swift
//  testModel
//
//  Created by Dale Carman on 10/23/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct LabView: View {

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Audio-lab-scene", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)

                // Put skybox here.  See example in World project available at
                // https://developer.apple.com/
            }
        }
    }
}

