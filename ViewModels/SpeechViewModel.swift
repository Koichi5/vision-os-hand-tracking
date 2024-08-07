//
//  SpeechViewModel.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/07/31.
//

import SwiftUI
import AVFoundation

@MainActor
class SpeechViewModel: NSObject, ObservableObject {
    static let shared = SpeechViewModel()
    private var synthesizer = AVSpeechSynthesizer()

    @Published var isSpeaking: Bool = false
    @Published var currentLanguage: SpeechLanguage = .english
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(text: String, speechSpeed: SpeechSpeed) {
        let speechUtterance = AVSpeechUtterance(string: text)
        
        speechUtterance.voice = AVSpeechSynthesisVoice(language: currentLanguage.rawValue)
        speechUtterance.rate = speechSpeed.speakSpeed
        synthesizer.speak(speechUtterance)
    }
    
    func setLanguage(_ language: SpeechLanguage) {
        currentLanguage = language
    }
}

extension SpeechViewModel: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
