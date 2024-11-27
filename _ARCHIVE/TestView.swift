//
//  TestView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 11/25/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct TestView: View {
    var body: some View {
        RealityView { content in
            do {
                let immersiveContentEntity = try await Entity(named: "CancerCell-spawn", in: realityKitContentBundle)
                immersiveContentEntity.position = [-0.5, 1.5, -1.5]
                content.add(immersiveContentEntity)
                print("Successfully loaded immersiveContentEntity.")
            } catch {
                print("Failed to load immersiveContentEntity: \(error)")
            }
            
            // Put skybox here.  See example in World project available at
            // https://developer.apple.com/
        }
    }
}
