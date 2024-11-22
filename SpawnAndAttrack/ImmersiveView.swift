//
//  ImmersiveView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 11/19/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @State private var rootEntity: Entity?

    var body: some View {
        RealityView { content in
            // Create a root entity for our content
            let root = Entity()
            content.add(root)
            rootEntity = root
            
            // Add some lighting to the scene
            let directionalLight = DirectionalLight()
            directionalLight.light.intensity = 1000
            directionalLight.position = [0, 1.5, 2]
            directionalLight.look(at: [0, 0, 0], from: directionalLight.position, relativeTo: nil)
            root.addChild(directionalLight)
            
            // Load the immersive content if available
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                root.addChild(immersiveContentEntity)
            }
            
        } update: { content in
            // Updates handled by root entity
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    print("\n=== New Tap Detected ===")
                    
                    // Get the tapped entity
                    if let tappedEntity = value.entity as? ModelEntity {
                        print("Tapped entity position: \(tappedEntity.position)")
                        
                        // Determine sphere radius based on position (left = 0.2, right = 0.1)
                        let isLeftSphere = tappedEntity.position.x < 0
                        let sphereRadius: Float = isLeftSphere ? 0.2 : 0.1
                        print("Sphere side: \(isLeftSphere ? "LEFT" : "RIGHT")")
                        print("Sphere radius: \(sphereRadius)")
                        
                        // Random position in front for initial spawn
                        let spawnPosition = SIMD3<Float>(
                            Float.random(in: -0.25...0.25),     // X: 4m wide range
                            Float.random(in: 0.25...1.1),      // Y: Up to 2m high
                            Float.random(in: -1.0 ... -0.25)    // Z: 0.25m to 1m away
                        )
                        print("Spawn position: \(spawnPosition)")
                        
                        // Calculate random point on sphere surface
                        let theta = Float.random(in: 0...(2 * .pi))  // Azimuthal angle
                        let phi = Float.random(in: 0...(.pi))        // Polar angle
                        
                        print("\nSphere Surface Calculation:")
                        print("Theta (azimuthal): \(theta) radians (\(theta * 180/Float.pi)°)")
                        print("Phi (polar): \(phi) radians (\(phi * 180/Float.pi)°)")
                        
                        // Calculate point on sphere surface using spherical coordinates
                        let sinPhi = sin(phi)
                        let cosPhi = cos(phi)
                        let cosTheta = cos(theta)
                        let sinTheta = sin(theta)
                        
                        // Calculate offset from sphere center
                        let offsetX = sphereRadius * sinPhi * cosTheta
                        let offsetY = sphereRadius * sinPhi * sinTheta
                        let offsetZ = sphereRadius * cosPhi
                        
                        print("\nOffset from sphere center:")
                        print("X offset: \(offsetX)")
                        print("Y offset: \(offsetY)")
                        print("Z offset: \(offsetZ)")
                        
                        // Calculate final target position
                        let targetPosition = SIMD3<Float>(
                            tappedEntity.position.x + offsetX,
                            tappedEntity.position.y + offsetY,
                            tappedEntity.position.z + offsetZ
                        )
                        
                        // Verify the distance
                        let displacement = targetPosition - tappedEntity.position
                        let actualDistance = sqrt(displacement.x * displacement.x + 
                                               displacement.y * displacement.y + 
                                               displacement.z * displacement.z)
                        
                        print("\nFinal Calculations:")
                        print("Target position: \(targetPosition)")
                        print("Distance from sphere center: \(actualDistance)")
                        print("Expected radius: \(sphereRadius)")
                        print("Distance error: \(abs(actualDistance - sphereRadius))")
                        
                        if abs(actualDistance - sphereRadius) > 0.001 {
                            print("WARNING: Target point is not exactly on sphere surface!")
                        }
                        
                        spawnAndAnimateCube(from: spawnPosition, to: targetPosition)
                    }
                }
        )
    }
    
    private func spawnAndAnimateCube(from startPosition: SIMD3<Float>, to endPosition: SIMD3<Float>) {
        guard let root = rootEntity else {
            print("Root entity not found")
            return
        }
        
        // Create a smaller cube (2cm)
        let mesh = MeshResource.generateBox(size: 0.02)
        let material = SimpleMaterial(color: .red, isMetallic: false)
        let cubeEntity = ModelEntity(mesh: mesh, materials: [material])
        
        // Set initial position in world space
        cubeEntity.position = startPosition
        
        // Add collision and input target components
        cubeEntity.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: [0.02, 0.02, 0.02])])
        cubeEntity.components[InputTargetComponent.self] = InputTargetComponent()
        
        root.addChild(cubeEntity)
        print("Spawned cube at: \(startPosition)")
        
        // Create transform for final position, also in world space
        var finalTransform = Transform(
            scale: cubeEntity.scale,
            rotation: cubeEntity.orientation,
            translation: endPosition
        )
        
        // Animate to final position in world space
        cubeEntity.move(
            to: finalTransform,
            relativeTo: nil,  // Use world space coordinates
            duration: 1.0,
            timingFunction: .easeInOut
        )
        
        print("Animating cube to: \(endPosition)")
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
