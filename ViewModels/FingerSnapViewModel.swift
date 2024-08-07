//
//  FingerSnapViewModel.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/08/04.
//

import SwiftUI
import RealityKit
import ARKit

@MainActor
class FingerSnapViewModel: ObservableObject {
    private let session = ARKitSession()
    private var leftHandAnchor: HandAnchor?
    private var rightHandAnchor: HandAnchor?
    private var handTrackingProvider: HandTrackingProvider?
    
    @Published var isFingerSnapReady: Bool = false
    @Published var isAllFingersBended: Bool = false
    @MainActor @Published var isFingerSnapDone: Bool = false
    
    static let shared = FingerSnapViewModel()
    
    init() {
        handTrackingProvider = HandTrackingProvider()
    }
    
    func start() async {
        do {
            try await session.run([handTrackingProvider!])
            print("Hand tracking session started successfully")
            await handleHandUpdates()
        } catch {
            print("Failed to start hand tracking session: \(error)")
        }
    }
    
    private func handleHandUpdates() async {
        for await update in handTrackingProvider!.anchorUpdates {
            let handAnchor = update.anchor
            
            if handAnchor.isTracked {
                if handAnchor.chirality == .left {
                    self.leftHandAnchor = handAnchor
                } else {
                    self.rightHandAnchor = handAnchor
                }
                // 右手で finger snap
                isFingerSnapReady = self.isFingerSnapReady(hand: .right)
                isFingerSnapDone = self.isFingerSnapDone(hand: .right)
                isAllFingersBended = self.isAllFingersBend(hand: .right) && isAllFingersBend(hand: .left)
            } else {
                print("Hand is not tracked")
                if handAnchor.chirality == .left {
                    self.leftHandAnchor = nil
                } else {
                    self.rightHandAnchor = nil
                }
            }
        }
    }
    
    private func isStraight(hand: Hands, finger: Fingers) -> Bool {
        if finger == .thumb {
            return isThumbExtended(hand: hand)
        }
        
        guard let tipPosition = extractPosition2D(jointPosition(hand: hand, finger: finger, joint: .tip)),
              let secondPosition = extractPosition2D(jointPosition(hand: hand, finger: finger, joint: .pip)),
              let wristPosition = extractPosition2D(jointPosition(hand: hand, finger: .wrist, joint: .tip)) else {
            return false
        }
        
        let tipToWristDistance = wristPosition.distance(to: tipPosition)
        let secondToWristDistance = wristPosition.distance(to: secondPosition)
        
        return secondToWristDistance < tipToWristDistance * 1.0
    }
    
    private func isBend(hand: Hands, finger: Fingers) -> Bool {
        let tipPosition: CGPoint? = extractPosition2D(jointPosition(hand:hand, finger:finger, joint: .tip))
        let secondPosition: CGPoint? = extractPosition2D(jointPosition(hand:hand, finger:finger, joint: .pip))
        let wristPosition: CGPoint? = extractPosition2D(jointPosition(hand:hand, finger:.wrist, joint: .tip))
        guard let tipPosition, let secondPosition, let wristPosition else { return false }
        
        if wristPosition.distance(to: secondPosition) > wristPosition.distance(to: tipPosition) { return true }
        return false
    }
    
    // 指先が触れているかどうかの判定
    private func isTipTouching(hand: Hands, finger1: Fingers, finger2: Fingers) -> Bool {
        let finger1TipPosition: CGPoint? = extractPosition2D(jointPosition(hand: hand, finger: finger1, joint: .tip))
        let finger2TipPosition: CGPoint? = extractPosition2D(jointPosition(hand: hand, finger: finger2, joint: .tip))
        guard let finger1TipPosition, let finger2TipPosition else { return false }
        
        if finger1TipPosition.distance(to: finger2TipPosition) < 0.01 { return true }
        return false
    }
    
    private func isThumbExtended(hand: Hands) -> Bool {
        guard let thumbTipPosition = extractPosition2D(jointPosition(hand: hand, finger: .thumb, joint: .tip)),
              let thumbIPPosition = extractPosition2D(jointPosition(hand: hand, finger: .thumb, joint: .pip)),
              let thumbCMCPosition = extractPosition2D(jointPosition(hand: hand, finger: .thumb, joint: .mcp)) else {
            return false
        }
        
        let distalSegmentLength = thumbIPPosition.distance(to: thumbTipPosition)
        let proximalSegmentLength = thumbCMCPosition.distance(to: thumbIPPosition)
        
        let extensionThreshold = 1.5
        return distalSegmentLength > proximalSegmentLength * extensionThreshold
    }
    
    // detect finger snap
    func isFingerSnapReady(hand: Hands) -> Bool {
        var check = 0
        if isStraight(hand: hand, finger: .thumb){ check += 1 }
        if isStraight(hand: hand, finger: .index){ check += 1 }
        if isStraight(hand: hand, finger: .middle){ check += 1 }
        if isBend(hand: hand, finger: .ring){ check += 1 }
        if isBend(hand: hand, finger: .little){ check += 1 }
//        if isTipTouching(hand: hand, finger1: .thumb, finger2: .middle){ check += 1 }
        if check == 5 { return true }
        return false
    }
    
    func isFingerSnapDone(hand: Hands) -> Bool {
        var check = 0
        if isStraight(hand: hand, finger: .thumb){ check += 1 }
        if isStraight(hand: hand, finger: .index){ check += 1 }
        if isBend(hand: hand, finger: .middle){ check += 1 }
        if isBend(hand: hand, finger: .ring){ check += 1 }
        if isBend(hand: hand, finger: .little){ check += 1 }
        if check == 5 { return true }
        return false
    }
    
    func isAllFingersBend(hand: Hands) -> Bool {
        var check = 0
//        if isBend(hand: hand, finger: .thumb){ check += 1 }
        if isBend(hand: hand, finger: .index){ check += 1 }
        if isBend(hand: hand, finger: .middle){ check += 1 }
        if isBend(hand: hand, finger: .ring){ check += 1 }
        if isBend(hand: hand, finger: .little){ check += 1 }
        print("--- isAllFingersBend check point: \(check) ---")
        return check == 4
    }
    
    private func extractPosition2D(_ transform: simd_float4x4?) -> CGPoint? {
        guard let transform = transform else { return nil }
        let position = transform.columns.3
        return CGPoint(
            x: CGFloat(position.x),
            y: CGFloat(position.y)
        )
    }
    
    private func jointPosition(hand: Hands, finger: Fingers, joint: JointType) -> simd_float4x4? {
        let anchor = hand == .left ? leftHandAnchor : rightHandAnchor
        guard let skeleton = anchor?.handSkeleton else {
            print("Skeleton not available for \(hand) hand")
            return nil
        }
        
        let jointName: HandSkeleton.JointName
        switch (finger, joint) {
        case (.thumb, .tip): jointName = .thumbTip
        case (.thumb, .pip): jointName = .thumbIntermediateBase
        case (.thumb, .mcp): jointName = .thumbIntermediateTip
        case (.index, .tip): jointName = .indexFingerTip
        case (.index, .pip): jointName = .indexFingerIntermediateBase
        case (.middle, .tip): jointName = .middleFingerTip
        case (.middle, .pip): jointName = .middleFingerIntermediateBase
        case (.ring, .tip): jointName = .ringFingerTip
        case (.ring, .pip): jointName = .ringFingerIntermediateBase
        case (.little, .tip): jointName = .littleFingerTip
        case (.little, .pip): jointName = .littleFingerIntermediateBase
        case (.wrist, .tip): jointName = .wrist
        default:
            print("Invalid joint combination: \(finger), \(joint)")
            return nil
        }
        
        let transform = skeleton.joint(jointName).anchorFromJointTransform
        print("Joint position for \(hand) hand, \(finger) finger, \(joint) joint: \(transform)")
        return transform
    }
}
