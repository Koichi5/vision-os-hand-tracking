//
//  HandTrackingCountView.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/07/17.
//

import SwiftUI
import RealityKit
import ARKit

// When user made Finger Snap Gesture, new Studio ImmersiveSpace will open
struct HandTrackingCountView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @State private var viewModel = ImmersiveViewModel()
    @StateObject private var fingerSnapViewModel = FingerSnapViewModel.shared
    
    var body: some View {
        RealityView { content in
            content.add(viewModel.rootEntity)
        }
        .onChange(of: fingerSnapViewModel.isFingerSnapDone) {
            if (fingerSnapViewModel.isFingerSnapDone) {
                print("--- fingerSnapViewModel.isFingerSnapDone: \(fingerSnapViewModel.isFingerSnapDone) ---")
                Task {
                    await viewModel.setupRootEntity()
                    appModel.phase = .playing
                }
            }
        }
        .onChange(of: appModel.phase) {
            if appModel.phase == .playing {
                print("--- appModel.phase is playing ---")
                viewModel.playAnimation()
                openWindow(id: "SpeechSampleContentView")
            }
        }
        .onChange(of: appModel.wantsToPresentImmersiveSpace) {
            if appModel.wantsToPresentImmersiveSpace {
                appModel.isPresentingImmersiveSpace = true
            } else {
                appModel.isPresentingImmersiveSpace = false
                appModel.phase = .waitingToStart
            }
        }
        .onChange(of: fingerSnapViewModel.isAllFingersBended) { _, newValue in
            if (newValue) {
                Task {
                    await dismissImmersiveSpace()
                    
                    viewModel.playCloseAnimation()
                }
            }
        }
    }
}
