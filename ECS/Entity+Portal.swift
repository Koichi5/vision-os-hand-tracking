//
//  Entity+Porta.swift
//  visionOS2_30Days_sample
//
//  Created by Koichi Kishimoto on 2024/07/27.
//

import Foundation
import RealityKit

import Studio

extension Entity {
    // portal とその中にある世界の両方を含むモデルを構築。
    static func makePortal() async throws -> Entity {
        let portal = Entity()
        portal.name = "portal"
        
        let worldEntity = try await makeWorldEntity()
        portal.addChild(worldEntity)
        portal.components.set(
            PortalComponent(
                target: worldEntity,
                clippingMode: .plane(.positiveZ),
                crossingMode: .plane(.negativeZ)
            )
        )
        
        portal.components.set(
            ModelComponent(
                mesh: .generatePlane(width: AppModel.portalWidth, height: AppModel.portalHeight, cornerRadius: 0.2), materials: [PortalMaterial()]
            )
        )
        
        return portal
    }
    
    // portal の中にある世界の構築。今回は Studio モデルを読み込む
    private static func makeWorldEntity() async throws -> Entity {
        let worldEntity = Entity()
        worldEntity.components.set(WorldComponent())
        worldEntity.name = "world"
        
        let studio = try await Entity(named: "Studio", in: studioBundle)
        studio.position = [0, -1.5, 0] // place portal studio in front of user
        worldEntity.addChild(studio)
        
        let textEntity = Entity()
        textEntity.name = "text"
        let text = makeText(text: "Hello visionOS 2!", containerWidth: AppModel.portalWidth, containerHeight: AppModel.portalHeight)
        textEntity.addChild(text)
        textEntity.components.set(PortalCrossingComponent())
        
        worldEntity.addChild(textEntity)
        
        return worldEntity
    }
    
    // portal の手前に表示させるテキストの構築
    private static func makeText(text: String, containerWidth: Float, containerHeight: Float) -> ModelEntity {
        let fontSize: CGFloat = 0.4
        
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.1,
            font: .boldSystemFont(ofSize: fontSize),
            containerFrame: CGRect(
                origin: .zero,
                size: CGSize(
                    width: Double(containerWidth),
                    height: Double(containerHeight)
                )
            ),
            alignment: .center
        )
        
        let entity = ModelEntity(
            mesh: mesh,
            materials: [
                SimpleMaterial(color: SimpleMaterial.Color(white: 0.9, alpha: 1.0), roughness: 0.5, isMetallic: true)
            ]
        )
        
        entity.components.set(EnvironmentLightingFadeComponent())
        // スクリーンの幅の半分 = ユーザーの目線の中心
        entity.position.x = -containerWidth / 2
        // ユーザーの目線の高さ - スクリーンの高さ + 文字の大きさ
        entity.position.y = -containerHeight + Float(fontSize / 2)
        // ユーザーの3m前
        entity.position.z = -3.0
        
        return entity
    }
}
