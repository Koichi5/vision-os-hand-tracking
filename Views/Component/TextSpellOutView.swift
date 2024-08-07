//
//  TextSpellOutView.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/08/04.
//

import SwiftUI

struct TextSpellOutView: View {
    var words: [String]
    let textSize: Double
    let maxWordsPerLine: Int
    let isDecorated: Bool
    let speechSpeed: SpeechSpeed
    
    @Binding var startAnimation: Bool
    @State private var visibleWords: Int = 0
    @State private var visibleChars: Int = 0
    @State private var isAnimationComplete: Bool = false
    @State private var timer: Timer?

    init(
        text: String,
        textSize: Double,
        maxWordsPerLine: Int = 5,
        isDecorated: Bool = false,
        startAnimation: Binding<Bool>,
        speechSpeed: SpeechSpeed
    ) {
        words = text.split(separator: " ").map(String.init)
        self.textSize = textSize
        self.maxWordsPerLine = maxWordsPerLine
        self.isDecorated = isDecorated
        self.speechSpeed = speechSpeed
        self._startAnimation = startAnimation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(0..<(words.count / maxWordsPerLine + 1), id: \.self) { lineIndex in
                HStack(spacing: 5) {
                    ForEach(0..<min(maxWordsPerLine, words.count - lineIndex * maxWordsPerLine), id: \.self) { wordIndex in
                        let index = lineIndex * maxWordsPerLine + wordIndex
                        let word = words[index]
                        HStack(spacing: 1) {
                            ForEach(0..<word.count, id: \.self) { charIndex in
                                Text(String(word[word.index(word.startIndex, offsetBy: charIndex)]))
                                    .font(.system(size: textSize))
                                    .foregroundColor(isDecorated ? .cyan : .primary)
                                    .shadow(color: isDecorated ? .cyan.opacity(0.7) : .clear, radius: 5, x: 0, y: 0)
                                    .opacity(isAnimationComplete || index < visibleWords || (index == visibleWords && charIndex < visibleChars) ? 1 : 0)
                            }
                        }
                    }
                }
            }
        }
        .blur(radius: isDecorated ? 0.5 : 0)
        .onChange(of: startAnimation) { _, newValue in
            if newValue {
                beginAnimation(speechSpeed: speechSpeed)
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func beginAnimation(speechSpeed: SpeechSpeed) {
        resetAnimation()
        timer = Timer.scheduledTimer(withTimeInterval: speechSpeed.letterInterval, repeats: true) { _ in
            if visibleWords < words.count {
                if visibleChars < words[visibleWords].count {
                    visibleChars += 1
                } else {
                    visibleWords += 1
                    visibleChars = 0
                }
            } else {
                timer?.invalidate()
                isAnimationComplete = true
                startAnimation = false
            }
        }
    }

    private func resetAnimation() {
        timer?.invalidate()
        visibleWords = 0
        visibleChars = 0
        isAnimationComplete = false
    }
}
