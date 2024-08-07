//
//  EnvironmentLightingFade.swift
//  visionOS2_30Days_sample
//
//  Created by Koichi Kishimoto on 2024/07/27.
//

import Foundation
import RealityKit

struct EnvironmentLightingFadeComponent: Component {
    init() {
        EnvironmentLightingFadeComponent.registerComponent()
        EnvironmentLightingFadeSystem.registerSystem()
    }
}

final class EnvironmentLightingFadeSystem: System {
    var elapsedTime: TimeInterval = 0
    init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        elapsedTime += context.deltaTime
        
        // PortalComponent を持つ Entity を探して portals に格納している
        let portals = context.entities(matching: EntityQuery(where: .has(PortalComponent.self)), updatingSystemWhen: .rendering)
        // portals のうち、PortalComponent が nill でない最初の entity を portal として扱う
        let portal = portals.first { entity in
            entity.components[PortalComponent.self] != nil
        }
        
        guard let portal else { return }
        
        for entity in context.entities(matching: EntityQuery(where: .has(EnvironmentLightingFadeComponent.self)), updatingSystemWhen: .rendering) {
            
            let distance = computeDistanceFromPortal(entity: entity, portal: portal)
            let weight = mapDistanceToWeight(distance: distance)
            
            portal.components.set(EnvironmentLightingConfigurationComponent(environmentLightingWeight: weight))
        }
    }
    
    func computeDistanceFromPortal(entity: Entity, portal: Entity) -> Float {
        let vector = entity.position(relativeTo: nil) - portal.position(relativeTo: nil)
        let portalForward = portal.transformMatrix(relativeTo: nil).forward * -1
        let distance = SIMD3<Float>.dot(portalForward, vector)
        return distance
    }
    
    func mapDistanceToWeight(distance: Float) -> Float {
        let maxDistance: Float = 0.15
        let minDistance: Float = 0.1
        if distance > maxDistance {
            return 1.0
        } else if (distance > minDistance) {
            return (distance - minDistance) / (maxDistance - minDistance)
        } else {
            return 0
        }
    }
}
