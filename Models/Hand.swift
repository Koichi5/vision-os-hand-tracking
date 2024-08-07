//
//  Hand.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/08/04.
//

enum HandGesture {
    case notTracked
    case closed
    case custom(Int)
}

enum Hands {
    case left
    case right
}

enum Fingers {
    case thumb
    case index
    case middle
    case ring
    case little
    case wrist
}

enum JointType {
    case tip
    case pip
    case dip
    case mcp
}
