//
//  SpeechSpeed.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/08/04.
//

enum SpeechSpeed: String, CaseIterable, Identifiable {
    case slow = "slow"
    case medium = "medium"
    case fast = "fast"
    
    var id: String { self.rawValue }

    var speakSpeed: Float {
        switch self {
        case .slow:
            return 0.3
        case .medium:
            return 0.5
        case .fast:
            return 0.6
        }
    }
    
    var letterInterval: Double {
        switch self {
        case .slow:
            return 0.08
        case .medium:
            return 0.06
        case .fast:
            return 0.04
        }
    }
    
    var displayName: String {
        switch self {
        case .slow:
            return "Slow"
        case .medium:
            return "Medium"
        case .fast:
            return "Fast"
        }
    }
}
