//
//  FingerSnapContentView.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/08/04.
//

import SwiftUI

struct FingerSnapContentView: View {
    
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    @StateObject private var fingerSnapViewModel = FingerSnapViewModel.shared
    @State private var immersiveViewModel = ImmersiveViewModel()
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    @State private var currentImmersiveSpace: String?
    @State private var hasProcessedFingerSnap = false
    
    var body: some View {
        VStack {
            if (fingerSnapViewModel.isFingerSnapReady) {
                Text("Let's ...")
                    .font(.title2)
            }
            if (fingerSnapViewModel.isFingerSnapDone) {
                Text("Work")
                    .font(.title)
            }
            if (fingerSnapViewModel.isAllFingersBended) {
                Text("Good job !")
                    .font(.title)
            }
//            Text("fingerSnapViewModel.isFingerSnapDone: \(fingerSnapViewModel.isFingerSnapDone)")
//            Text("fingerSnapViewModel.isAllFingersBended: \(fingerSnapViewModel.isAllFingersBended)")
//            Text("currentImmersiveSpace: \(String(describing: currentImmersiveSpace))")
            Toggle("Hand Tracking", isOn: $showImmersiveSpace)
                .toggleStyle(.button)
                .padding(.top, 50)
            Button {
                Task {
                    await openImmersiveSpace(id: "ImmersiveSpace")
                }
            } label: {
                Text("Immersive space")
            }
        }
        // showImmeriveSpace の変化を検知。true であれば HandTracking ImmersiveView を開く
        // TODO: Check: Window, Volume の段階で viewModel.start() を実行してハンドトラッキングができるのか
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    await openHandTrackingSpace()
                } else if immersiveSpaceIsShown {
                    await closeCurrentImmersiveSpace()
                }
            }
        }
//        .onChange(of: fingerSnapViewModel.isFingerSnapDone) { _, newValue in
//            if newValue {
//                Task {
//                    await dismissImmersiveSpace(id: "HandTracking")
//                    await openImmersiveSpace(id: "ImmersiveSpace")
//                }
//            }
////            if newValue && !hasProcessedFingerSnap {  // フラグをチェック
////                Task {
////                    hasProcessedFingerSnap = true  // フラグを設定
////                    if currentImmersiveSpace != "ImmersiveSpace" {  // 既に開いていないかチェック
////                        await closeCurrentImmersiveSpace()
////                        await openImmersiveSpace()
////                    }
////                }
////            } else if !newValue {
////                hasProcessedFingerSnap = false  // リセット
////            }
//        }
//        .onChange(of: appModel.phase) {
//            if appModel.phase == .playing {
//                immersiveViewModel.playAnimation()
//            }
//        }
//        .onChange(of: appModel.wantsToPresentImmersiveSpace) {
//            if appModel.wantsToPresentImmersiveSpace {
//                appModel.isPresentingImmersiveSpace = true
//            } else {
//                appModel.isPresentingImmersiveSpace = false
//                appModel.phase = .waitingToStart
//            }
//        }
    }
    
    private func openHandTrackingSpace() async {
        if currentImmersiveSpace != "HandTracking" {
            switch await openImmersiveSpace(id: "HandTracking") {
            case .opened:
                immersiveSpaceIsShown = true
                currentImmersiveSpace = "HandTracking"
                await fingerSnapViewModel.start()
            case .error, .userCancelled:
                fallthrough
            @unknown default:
                immersiveSpaceIsShown = false
                showImmersiveSpace = false
            }
        }
    }
    
    private func openStudioImmersiveSpace() async {
        if currentImmersiveSpace != "ImmersiveSpace" {
            do {
                let result = await openImmersiveSpace(id: "ImmersiveSpace")
                switch result {
                case .opened:
                    immersiveSpaceIsShown = true
                    currentImmersiveSpace = "ImmersiveSpace"
                    await immersiveViewModel.setupRootEntity()
                    appModel.phase = .playing
                case .error:
                    print("Failed to open ImmersiveSpace")
                    immersiveSpaceIsShown = false
                case .userCancelled:
                    print("User cancelled opening ImmersiveSpace")
                    immersiveSpaceIsShown = false
                @unknown default:
                    print("Unknown result when opening ImmersiveSpace")
                    immersiveSpaceIsShown = false
                }
            }
        }
    }
    
    private func closeCurrentImmersiveSpace() async {
        if immersiveSpaceIsShown {
            await dismissImmersiveSpace()
            immersiveSpaceIsShown = false
            currentImmersiveSpace = nil
        }
    }
}

#Preview {
    FingerSnapContentView()
}
