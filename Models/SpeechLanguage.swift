//
//  SpeechLanguage.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/08/06.
//

enum SpeechLanguage: String, CaseIterable, Identifiable {
    case english = "en-US"
    case japanese = "ja-JP"
    case spanish = "es-ES"
    case french = "fr-FR"
    case german = "de-DE"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        }
    }
}
