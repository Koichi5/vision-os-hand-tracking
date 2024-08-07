//
//  AppModel.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/07/15.
//

import SwiftUI
import RealityKit
import Observation

enum AppPhase: CaseIterable, Codable, Identifiable, Sendable {
    case waitingToStart
    case playing
    
    public var id: Self { self }
}

@MainActor
@Observable
class AppModel {
    static let portalWidth: Float = 4
    static let portalHeight: Float = 3
    
    var phase = AppPhase.waitingToStart
    
    var isPresentingImmersiveSpace = false
    var wantsToPresentImmersiveSpace = false
    
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
}
