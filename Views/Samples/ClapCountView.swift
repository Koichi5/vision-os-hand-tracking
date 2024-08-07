//
//  ClapCountView.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/08/01.
//

import SwiftUI

struct ClapCountView: View {
    @StateObject private var viewModel = HandTrackingViewModel.shared
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var body: some View {
        VStack {
            Text("is finger snap ready: \(viewModel.isFingerSnapReady)")
            Toggle("Hand Tracking", isOn: $showImmersiveSpace)
                .toggleStyle(.button)
                .padding(.top, 50)
        }
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "HandTracking") {
                    case .opened:
                        immersiveSpaceIsShown = true
                        await viewModel.startHandTracking()
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                }
            }
        }
    }
}

#Preview {
    ClapCountView()
}
