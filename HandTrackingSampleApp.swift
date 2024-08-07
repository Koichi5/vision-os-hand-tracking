//
//  HandTrackingSampleApp.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/07/15.
//

import SwiftUI

@main
struct HandTrackingSampleApp: App {
    @State private var appModel = AppModel()
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var body: some Scene {
        WindowGroup {
//            SpeechSampleContentView()
//            ClapCountView()
//            SpeechSampleContentView()
//            HandTrackingCountContentView()
            FingerSnapContentView()
                .environment(appModel)
        }
        // TODO: Info.plist の Application Scene Manifest > Preferred Default Scene Session Role を volume, window で切り替える必要がある
        .windowStyle(.volumetric)
        
        WindowGroup(id: "SpeechSampleContentView") {
            SpeechSampleContentView()
        }
        .windowStyle(.volumetric)
        
        ImmersiveSpace(id: "HandTracking") {
            HandTrackingCountView()
                .environment(appModel)
        }
        
        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environment(appModel)
        }
        .onChange(of: appModel.wantsToPresentImmersiveSpace) {
            appModel.isPresentingImmersiveSpace = true
        }
        .onChange(of: appModel.isPresentingImmersiveSpace) {
            Task {
                if appModel.isPresentingImmersiveSpace {
                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
                    case .opened:
                        appModel.isPresentingImmersiveSpace = true
                    case .error, .userCancelled:
                        fallthrough
                    default:
                        appModel.isPresentingImmersiveSpace = false
                    }
                }
            }
        }
    }
}
