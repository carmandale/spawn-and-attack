//
//  ToggleImmersiveSpaceButton.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 11/19/24.
//

import SwiftUI

struct ToggleImmersiveSpaceButton: View {

    @Environment(AppModel.self) private var appModel
    let spaceID: AppModel.ImmersiveSpaceID

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        Button {
            Task { @MainActor in
                switch appModel.immersiveSpaceState {
                    case .open:
                        appModel.immersiveSpaceState = .inTransition
                        await dismissImmersiveSpace()
                        // Don't set immersiveSpaceState to .closed because there
                        // are multiple paths to ImmersiveView.onDisappear().
                        // Only set .closed in ImmersiveView.onDisappear().

                    case .closed:
                        appModel.immersiveSpaceState = .inTransition
                        switch await openImmersiveSpace(id: spaceID.rawValue) {
                            case .opened:
                                appModel.currentSpace = spaceID
                                break

                            case .userCancelled, .error:
                                // On error, we need to mark the immersive space
                                // as closed because it failed to open.
                                fallthrough
                            @unknown default:
                                // On unknown response, assume space did not open.
                                appModel.immersiveSpaceState = .closed
                                appModel.currentSpace = nil
                        }

                    case .inTransition:
                        // This case should not ever happen because button is disabled for this case.
                        break
                }
            }
        } label: {
            Label(spaceID == .attackCancer ? "Attack Cancer" : "Lab View",
                  systemImage: appModel.immersiveSpaceState == .open ? "xmark" : "play.fill")
        }
        .disabled(appModel.immersiveSpaceState == .inTransition || 
                 (appModel.immersiveSpaceState == .open && appModel.currentSpace != spaceID))
        .animation(.none, value: 0)
        .fontWeight(.semibold)
    }
}
