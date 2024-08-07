//
//  HandTrackingViewModel.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/07/17.
//

import SwiftUI
import RealityKit
import ARKit

@MainActor
class HandTrackingViewModel: ObservableObject {
    @Published var leftHandGesture: HandGesture = .notTracked
    @Published var rightHandGesture: HandGesture = .notTracked
    
    private let session = ARKitSession()
    private var leftHandAnchor: HandAnchor?
    private var rightHandAnchor: HandAnchor?
    private var handTrackingProvider: HandTrackingProvider?
    
    static let shared = HandTrackingViewModel()
    
    // clap
    @Published var clapped: Bool = false
    @Published var doubleClapped: Bool = false
    @Published var clapCount: Int = 0
    private var lastClapTime: TimeInterval = 0
    private var handsCloseTime: TimeInterval? = nil
    private let clapThreshold: CGFloat = 0.2 // メートル単位（少し大きくしました）
    private let clapSpeed: TimeInterval = 0.3
    private var firstClapTime: TimeInterval?
    private let doubleClapTimeWindow: TimeInterval = 0.5
    private var lastLeftPosition: SIMD3<Float>?
    private var lastRightPosition: SIMD3<Float>?
    private var lastUpdateTime: TimeInterval?
    
    // finger sample
    @Published var isFingersTouching: Bool = false
    private let fingerTouchThreshold: CGFloat = 0.1
    
    
    // finger stretch
    @Published var displayedNumber: Int = 0
    
    // finger snap
    @Published var isFingerSnapReady: Bool = false
    @Published var isFingerSnapDone: Bool = false
    
    init() {
        handTrackingProvider = HandTrackingProvider()
    }
    
    func startHandTracking() async {
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
            
            print("Received hand update for \(handAnchor.chirality) hand. Tracked: \(handAnchor.isTracked)")
            
            if handAnchor.isTracked {
                if handAnchor.chirality == .left {
                    self.leftHandAnchor = handAnchor
                    self.leftHandGesture = self.determineHandGesture(hand: .left)
                } else {
                    self.rightHandAnchor = handAnchor
                    self.rightHandGesture = self.determineHandGesture(hand: .right)
                }
                self.updateDisplayedNumber()
                self.updateHandPositions()
                // 右手で finger snap
                isFingerSnapReady = self.isFingerSnapReady(hand: .right)
                isFingerSnapDone = self.isFingerSnapDone(hand: .right)
            } else {
                print("Hand is not tracked")
                if handAnchor.chirality == .left {
                    self.leftHandAnchor = nil
                    self.leftHandGesture = .notTracked
                } else {
                    self.rightHandAnchor = nil
                    self.rightHandGesture = .notTracked
                }
            }
        }
    }
    
    // detect finger stretch
    func determineHandGesture(hand: Hands) -> HandGesture {
        let fingers: [Fingers] = [.thumb, .index, .middle, .ring, .little]
        let extendedFingers = fingers.filter { isStraight(hand: hand, finger: $0) }
        
        if extendedFingers.isEmpty {
            return .closed
        } else {
            return .custom(extendedFingers.count)
        }
    }
    
    private func updateDisplayedNumber() {
        _ = displayedNumber
        displayedNumber = [leftHandGesture, rightHandGesture].reduce(0) { total, gesture in
            switch gesture {
            case .custom(let count):
                return total + count
            default:
                return total
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
        if isTipTouching(hand: hand, finger1: .thumb, finger2: .middle){ check += 1 }
        if check == 6 { return true }
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
    
    
    // detect clap
    private func updateHandPositions() {
        guard let leftWrist = extractPosition3D(clapJointPosition(hand: .left, finger: .index, joint: .mcp)),
              let rightWrist = extractPosition3D(clapJointPosition(hand: .right, finger: .index, joint: .mcp)),
              let leftPalm = extractPosition3D(clapJointPosition(hand: .left, finger: .middle, joint: .mcp)),
              let rightPalm = extractPosition3D(clapJointPosition(hand: .right, finger: .middle, joint: .mcp)),
              let leftIndexTip = extractPosition2D(jointPosition(hand: .left, finger: .index, joint: .tip)),
              let rightIndexTip = extractPosition2D(jointPosition(hand: .right, finger: .index, joint: .tip))
        else {
            print("Hand positions not available")
            return
        }
        
        let currentTime = CACurrentMediaTime()
        let distance = simd_distance(leftWrist, rightWrist)
        //        let index_finger_distance = simd_distance(leftIndexTip, rightIndexTip)
        let index_finger_distance = leftIndexTip.distance(to: rightIndexTip)
        //        return index_finger_distance > fingerTouchThreshold
        print("----- index_finger_distance: \(index_finger_distance) -----")
        
        DispatchQueue.main.async {
            self.isFingersTouching = index_finger_distance < self.fingerTouchThreshold
        }
        
        print("Left index tip position: \(leftIndexTip)")
        print("Right index tip position: \(rightIndexTip)")
        print("Finger distance: \(distance), Threshold: \(fingerTouchThreshold)")
        print("Fingers touching: \(isFingersTouching)")
        
        let leftPalmDirection = normalize(leftPalm - leftWrist)
        let rightPalmDirection = normalize(rightWrist - rightPalm)
        let palmAlignment = dot(leftPalmDirection, rightPalmDirection)
        
        if let lastLeft = lastLeftPosition, let lastRight = lastRightPosition, let lastTime = lastUpdateTime {
            let timeDelta = currentTime - lastTime
            let leftVelocity = (leftWrist - lastLeft) / Float(timeDelta)
            let rightVelocity = (rightWrist - lastRight) / Float(timeDelta)
            let relativeVelocity = leftVelocity - rightVelocity
            let approachSpeed = -dot(normalize(rightWrist - leftWrist), relativeVelocity)
            
            print("Left hand position: \(leftWrist)")
            print("Right hand position: \(rightWrist)")
            print("Hand distance: \(distance), Threshold: 0.15")
            print("Palm alignment: \(palmAlignment)")
            print("Approach speed: \(approachSpeed)")
            
            if distance < 0.15 && palmAlignment > -0.7 && approachSpeed > 0.2 {
                if handsCloseTime == nil {
                    print("Potential clap detected at time: \(currentTime)")
                    handsCloseTime = currentTime
                } else if currentTime - handsCloseTime! > 0.05 && currentTime - handsCloseTime! < 0.2 {
                    print("Clap confirmed!")
                    handleClap(at: currentTime)
                    handsCloseTime = nil
                }
            } else {
                handsCloseTime = nil
            }
        }
        
        lastLeftPosition = leftWrist
        lastRightPosition = rightWrist
        lastUpdateTime = currentTime
    }
    
    private func normalize(_ vector: SIMD3<Float>) -> SIMD3<Float> {
        return vector / simd_length(vector)
    }
    
    private func handleClap(at time: TimeInterval) {
        DispatchQueue.main.async {
            self.clapCount += 1
            print("Clap detected! Total claps: \(self.clapCount)")
        }
        if let firstClap = firstClapTime {
            let timeSinceFirstClap = time - firstClap
            if timeSinceFirstClap <= doubleClapTimeWindow {
                print("Double clap detected!")
                doubleClapped = true
                onDoubleClap()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.doubleClapped = false
                }
                firstClapTime = nil
            } else {
                firstClapTime = time
            }
        } else {
            firstClapTime = time
        }
        
        clapped = true
        lastClapTime = time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.clapped = false
        }
    }
    
    private func onDoubleClap() {
        print("Double clap detected!")
        // ここに二回拍手時に実行したい処理を追加
    }
    
    private func extractPosition3D(_ transform: simd_float4x4?) -> SIMD3<Float>? {
        guard let transform = transform else {
            print("Transform is nil")
            return nil
        }
        let position = transform.columns.3
        return SIMD3<Float>(position.x, position.y, position.z)
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
    
    private func clapJointPosition(hand: Hands, finger: Fingers, joint: JointType) -> simd_float4x4? {
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
        case (.index, .mcp): jointName = .indexFingerKnuckle
        case (.middle, .tip): jointName = .middleFingerTip
        case (.middle, .pip): jointName = .middleFingerIntermediateBase
        case (.middle, .mcp): jointName = .middleFingerKnuckle
        case (.ring, .tip): jointName = .ringFingerTip
        case (.ring, .pip): jointName = .ringFingerIntermediateBase
        case (.ring, .mcp): jointName = .ringFingerKnuckle
        case (.little, .tip): jointName = .littleFingerTip
        case (.little, .pip): jointName = .littleFingerIntermediateBase
        case (.little, .mcp): jointName = .littleFingerKnuckle
        case (.wrist, .tip): jointName = .wrist
        default:
            print("Invalid joint combination: \(finger), \(joint)")
            return nil
        }
        
        return skeleton.joint(jointName).anchorFromJointTransform
    }
}

extension SIMD4 {
    var _xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

extension CGPoint {
    public var length: CGFloat {
        return hypot(x, y)
    }
    
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
    
    //    public func distance(from point: CGPoint) -> CGFloat {
    //        return (self - point).length
    //    }
}
