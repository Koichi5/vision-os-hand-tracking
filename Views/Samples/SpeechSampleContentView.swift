//
//  SpeechSampleContentView.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/07/31.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct SpeechSampleContentView: View {
    @StateObject private var speechViewModel = SpeechViewModel.shared
    @State private var textToSpeak: String = "Good morning, sir. It's currently 9:15 AM. The weather in New York is sunny with a temperature of 72°F. Your schedule for today includes a Stark Industries board meeting at 11 AM and a meeting with S.H.I.E.L.D. at 2 PM. You have 3 unread messages from Pepper Potts. Also, it appears there's an urgent communication from Nick Fury."
    @State private var startTextAnimation = false
    @State private var isHologramActivated = false
    @Environment(\.realityKitScene) var scene
    
    let rkcb = realityKitContentBundle
    let rknt = "RealityKit.NotificationTrigger"
        
    fileprivate func notify(scene: RealityKit.Scene, animationName: String) {
      let notification = Notification(
        name: .init(rknt),
        userInfo: ["\(rknt).Scene" : scene,"\(rknt).Identifier" : animationName]
      )
      NotificationCenter.default.post(notification)
    }
    
    var body: some View {
        VStack {
            RealityView { content in
                if let hologram = try? await Entity(named: "Hologram", in: realityKitContentBundle) {
                    content.add(hologram)
                }
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        if let scene {
                            if(!isHologramActivated && !speechViewModel.isSpeaking && !startTextAnimation) {
                                notify(scene: scene, animationName: "Activate")
                                speechViewModel.speak(
                                    text: textToSpeak,
                                    speechSpeed: SpeechSpeed.medium
                                )
                                startTextAnimation = true
                                isHologramActivated = true
                                print("Hologram Activated: \(isHologramActivated)")
                            }
                        }
                    }
            )
            .onChange(of: speechViewModel.isSpeaking) { _, newValue in
                if(!newValue) {
                    if let scene {notify(scene: scene, animationName: "Inactivate")}
                    isHologramActivated = false
                    print("Hologram Inctivated: \(isHologramActivated)")
                }
            }
            
//            Button("Speak") {
//                speechViewModel.speak(text: textToSpeak, speed: 0.5)
//                startTextAnimation = true
//            }
//            .disabled(speechViewModel.isSpeaking || startTextAnimation)
//            .padding()
//            
//            Text(speechViewModel.isSpeaking ? "Speaking..." : "Not speaking")
//                .padding()
            
            TextSpellOutView(
                text: textToSpeak,
                textSize: 45,
                maxWordsPerLine: 8,
                isDecorated: false,
                startAnimation: $startTextAnimation,
                speechSpeed: SpeechSpeed.medium
            )
        }
    }
}

//struct SpeechSampleContentView: View {
//    @StateObject private var speechViewModel = SpeechViewModel.shared
//    private var textToSpeak: String = "Good morning, sir. It's currently 9:15 AM. The weather in New York is sunny with a temperature of 72°F. Your schedule for today includes a Stark Industries board meeting at 11 AM and a meeting with S.H.I.E.L.D. at 2 PM. You have 3 unread messages from Pepper Potts. Also, it appears there's an urgent communication from Nick Fury."
//    @State private var startTextAnimation = false
//    @State private var selectedLanguage: SpeechLanguage = .english
//    @State private var selectedSpeed: SpeechSpeed = .medium
//    
//    var body: some View {
//        VStack {
//            Picker("Language", selection: $selectedLanguage) {
//                ForEach(SpeechLanguage.allCases, id: \.self) { language in
//                    Text(language.displayName).tag(language)
//                }
//            }
//            .pickerStyle(SegmentedPickerStyle())
//            .padding()
//
//            Picker("Speed", selection: $selectedSpeed) {
//                ForEach(SpeechSpeed.allCases, id: \.self) { speed in
//                    Text(speed.displayName).tag(speed)
//                }
//            }
//            .pickerStyle(SegmentedPickerStyle())
//            .padding()
//
//            Button(speechViewModel.isSpeaking ? "Speaking..." : "Speak") {
//                speechViewModel.setLanguage(selectedLanguage)
//                speechViewModel.speak(text: textToSpeak, speechSpeed: selectedSpeed)
//                startTextAnimation = true
//            }
//            .disabled(speechViewModel.isSpeaking || startTextAnimation)
//            .padding()
//
//            TextSpellOutView(
//                text: textToSpeak,
//                textSize: 45,
//                maxWordsPerLine: 8,
//                isDecorated: true,
//                startAnimation: $startTextAnimation,
//                speechSpeed: selectedSpeed
//            )
//        }
//    }
//}
