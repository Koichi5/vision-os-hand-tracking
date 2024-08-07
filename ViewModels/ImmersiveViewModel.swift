//
//  ImmersiveViewModel.swift
//  HandTrackingSample
//
//  Created by Koichi Kishimoto on 2024/08/04.
//

import RealityKit
import SwiftUI

@MainActor
final class ImmersiveViewModel {
    @StateObject private var fingerSnapViewModel = FingerSnapViewModel.shared
    let rootEntity = Entity()
    
    func getTargetEntity(name: String) -> Entity? {
        return rootEntity.children.first { $0.name == name }
    }
    
    func setupRootEntity() async {
        print("--- setupRootEntity fired ---")
        do {
            let portal = try await Entity.makePortal()
            portal.position = [0.0, 1.5, -3.0]
            rootEntity.addChild(portal)
            
            try await addOccluder(targetEntity: portal)
        } catch {
            print(error)
        }
    }
    
    // OcclusionMaterial: https://developer.apple.com/documentation/realitykit/occlusionmaterial
    // portal を作成する際に、実際のユーザーの部屋をくり抜いて実装するため、その「くり抜く」処理が Occluder で可能
    // portal を覗き込んだ時の左右の壁かな？
    private func addOccluder(targetEntity: Entity) async throws {
        let position = targetEntity.position
        
        let leftWall = ModelEntity(
            mesh: .generateBox(width: AppModel.portalWidth / 2, height: AppModel.portalHeight, depth: 0.1),
            // この mesh で OcclusionMaterial を指定することで「くり抜く」処理が可能
            materials: [OcclusionMaterial()]
            // 青色でくり抜くことも可能
            //materials: [SimpleMaterial(color: SimpleMaterial.Color.blue, isMetallic: false)]
        )
        leftWall.position = [position.x - 1, position.y, position.z + 0.01]
        leftWall.name = "leftWall"
        rootEntity.addChild(leftWall)
        
        let rightWall = ModelEntity(
            mesh: .generateBox(width: AppModel.portalWidth / 2, height: AppModel.portalHeight, depth: 0.1),
            materials: [OcclusionMaterial()]
            //materials: [SimpleMaterial(color: SimpleMaterial.Color.red, isMetallic: false)]
        )
        rightWall.position = [position.x + 1, position.y, position.z + 0.01]
        rightWall.name = "rightWall"
        rootEntity.addChild(rightWall)
    }
    
    func playAnimation() {
        guard let portal = getTargetEntity(name: "portal"),
              let world = portal.children.first(where: { $0.name == "world" }),
              let leftWall = getTargetEntity(name: "leftWall"),
              let rightWall = getTargetEntity(name: "rightWall")
        else {
            debugPrint("Some entities not found")
            return
        }
        
        // duration秒かけてportalが開閉する
        let duration = 6.0
        
        // Left wall
        let leftWallPositionOrigin = leftWall.transform.translation
        
        let leftWallOpen = FromToByAnimation(
            name: "leftWallOpen",
            to: Transform(
                translation: [leftWallPositionOrigin.x - AppModel.portalWidth / 2, leftWallPositionOrigin.y, leftWallPositionOrigin.z]
            ),
            duration: duration,
            timing: .linear,
            bindTarget: .transform,
            delay: 1.0
        )

        // Right wall
        let rightWallPositionOrigin = rightWall.transform.translation

        let rightWallOpen = FromToByAnimation(
            name: "rightWallOpen",
            to: Transform(translation: [rightWallPositionOrigin.x + AppModel.portalWidth / 2, rightWallPositionOrigin.y, rightWallPositionOrigin.z]),
            duration: duration,
            timing: .linear,
            bindTarget: .transform,
            delay: 1.0
        )

        // left wall animation
        let leftWallOpenAnimation = try! AnimationResource.generate(with: leftWallOpen)
        
        // right wall animation
        let rightWallOpenAnimation = try! AnimationResource.generate(with: rightWallOpen)
        
        let leftWallAnimation = try! AnimationResource.sequence(
            with: [
                leftWallOpenAnimation
            ]
        )
        leftWall.playAnimation(leftWallAnimation)
        
        let rightWallAnimation = try! AnimationResource.sequence(
            with: [
                rightWallOpenAnimation
            ]
        )
        rightWall.playAnimation(rightWallAnimation)
    }
    
    func playCloseAnimation() {
        print("playCloseAnimation fired")
        guard let portal = getTargetEntity(name: "portal"),
              let world = portal.children.first(where: { $0.name == "world" }),
              let leftWall = getTargetEntity(name: "leftWall"),
              let rightWall = getTargetEntity(name: "rightWall")
        else {
            debugPrint("Some entities not found")
            return
        }
        
        // duration秒かけてportalが開閉する
        let duration = 6.0
        
        // Left wall
        let leftWallPositionOrigin = leftWall.transform.translation
        
        let leftWallClose = FromToByAnimation(
            name: "leftWallClose",
            from: Transform(translation: [leftWallPositionOrigin.x - AppModel.portalWidth / 2, leftWallPositionOrigin.y, leftWallPositionOrigin.z]),
            to: Transform(translation: leftWallPositionOrigin),
            duration: duration,
            timing: .linear,
            bindTarget: .transform
        )

        // Right wall
        let rightWallPositionOrigin = rightWall.transform.translation

        let rightWallClose = FromToByAnimation(
            name: "rightWallClose",
            from: Transform(translation: [rightWallPositionOrigin.x + AppModel.portalWidth / 2, rightWallPositionOrigin.y, rightWallPositionOrigin.z]),
            to: Transform(translation: rightWallPositionOrigin),
            duration: duration,
            timing: .linear,
            bindTarget: .transform
        )
        let leftWallCloseAnimation = try! AnimationResource.generate(with: leftWallClose)
        let rightWallCloseAnimation = try! AnimationResource.generate(with: rightWallClose)
        
        let leftWallAnimation = try! AnimationResource.sequence(
            with: [
                leftWallCloseAnimation
            ]
        )
        leftWall.playAnimation(leftWallAnimation)
        
        let rightWallAnimation = try! AnimationResource.sequence(
            with: [
                rightWallCloseAnimation
            ]
        )
        rightWall.playAnimation(rightWallAnimation)
    }
}
