//
//  ContentView.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/07/15.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct HandTrackingCountContentView: View {
    @StateObject private var viewModel = HandTrackingViewModel.shared
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("Left Hand")
                    Text("\(describeGesture(viewModel.leftHandGesture))")
                        .font(.title)
                        .padding()
                    HStack {
                        ForEach(0..<leftHandFingerCount, id: \.self) { _ in
                            Model3D(named: "Apple", bundle: realityKitContentBundle) { model in
                                model.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 50, height: 50)
                            .frame(depth: 50)
                        }
                    }
                }
                .padding()
                
                VStack {
                    Text("Right Hand")
                    Text("\(describeGesture(viewModel.rightHandGesture))")
                        .font(.title)
                        .padding()
                    HStack {
                        ForEach(0..<rightHandFingerCount, id: \.self) { _ in
                            Model3D(named: "Apple", bundle: realityKitContentBundle) { model in
                                model.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 50, height: 50)
                            .frame(depth: 50)
                        }
                    }
                }
                .padding()
            }
            
            Text("Total")
            Text("\(viewModel.displayedNumber)")
                .font(.title)
            HStack {
                ForEach(0..<viewModel.displayedNumber, id: \.self) { _ in
                    Model3D(named: "Apple", bundle: realityKitContentBundle) { model in
                        model.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 50, height: 50)
                    .frame(depth: 50)
                }
            }
            
            Toggle("Hand Tracking", isOn: $showImmersiveSpace)
                .toggleStyle(.button)
                .padding(.top, 50)
        }
        .padding()
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "HandTracking") {
                    case .opened:
                        immersiveSpaceIsShown = true
                        await viewModel.startHandTracking()
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                }
            }
        }
    }
    
    var leftHandFingerCount: Int {
        if case .custom(let count) = viewModel.leftHandGesture {
            return count
        }
        return 0
    }
    
    var rightHandFingerCount: Int {
        if case .custom(let count) = viewModel.rightHandGesture {
            return count
        }
        return 0
    }
    
    func describeGesture(_ gesture: HandGesture) -> String {
        switch gesture {
        case .notTracked:
            return "Not tracked"
        case .closed:
            return "0"
        case .custom(let count):
            return "\(count)"
        }
    }
}
