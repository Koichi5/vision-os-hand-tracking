//
//  ImmersiveView.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/08/04.
//

import SwiftUI
import RealityKit

struct ImmersiveView: View {
    
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = ImmersiveViewModel()
    @State private var fingerSnapViewModel = FingerSnapViewModel()
    
    var body: some View {
        RealityView { content in
            content.add(viewModel.rootEntity)
            
            Task {
                await viewModel.setupRootEntity()
                appModel.phase = .playing
            }
        }
        .onChange(of: appModel.phase) {
            if appModel.phase == .playing {
                viewModel.playAnimation()
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
    }
}
