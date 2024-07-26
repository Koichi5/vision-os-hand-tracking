//
//  HandTrackingSampleApp.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/07/15.
//

import SwiftUI

@main
struct HandTrackingSampleApp: App {
    var body: some Scene {
        WindowGroup {
            HandTrackingCountContentView()
        }
        
        ImmersiveSpace(id: "HandTracking") {
            HandTrackingCountView()
        }
    }
}
