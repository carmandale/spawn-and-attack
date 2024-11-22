//
//  CurvedPathView.swift
//  SpawnAndAttrack
//
//  Created by Dale Carman on 11/19/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct CurvedPathView: View {
    @Environment(AppModel.self) private var appModel
    @State private var rootEntity: Entity?
    
    var body: some View {
        RealityView { content in
            // Create root entity
            let root = Entity()
            content.add(root)
            rootEntity = root
            
            // Add lighting
            let directionalLight = DirectionalLight()
            directionalLight.light.intensity = 1000
            directionalLight.position = [0, 1.5, 2]
            directionalLight.look(at: [0, 0, 0], from: directionalLight.position, relativeTo: nil)
            root.addChild(directionalLight)
            
            // Load the immersive content if available
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                root.addChild(immersiveContentEntity)
            }
            
            // Add demonstration spheres
            addSpheres(to: root)
            
        } update: { content in
            // Updates handled by root entity
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    if let tappedEntity = value.entity as? ModelEntity {
                        handleTap(on: tappedEntity)
                    }
                }
        )
    }
    
    private func addSpheres(to root: Entity) {
        // Left sphere
        let leftSphere = ModelEntity(
            mesh: .generateSphere(radius: 0.2),
            materials: [SimpleMaterial(color: UIColor(red: 0, green: 0, blue: 1, alpha: 0.3), isMetallic: false)]
        )
        leftSphere.position = [-0.5, 1.5, -1.7421877]
        leftSphere.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.2)])
        root.addChild(leftSphere)
        
        // Right sphere
        let rightSphere = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            materials: [SimpleMaterial(color: UIColor(red: 1, green: 0, blue: 0, alpha: 0.3), isMetallic: false)]
        )
        rightSphere.position = [0.5, 1.5, -1.5]
        rightSphere.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.1)])
        root.addChild(rightSphere)
    }
    
    private func handleTap(on entity: ModelEntity) {
        let isLeftSphere = entity.position.x < 0
        let sphereRadius: Float = isLeftSphere ? 0.2 : 0.1
        let sphereCenter = entity.position
        
        // Generate random point on sphere surface
        let targetPoint = generateRandomPointOnSphere(center: sphereCenter, radius: sphereRadius)
        
        // Generate spawn point
        let spawnPoint = SIMD3<Float>(
            Float.random(in: -0.25...0.25),
            Float.random(in: 0.25...1.1),
            Float.random(in: -1.0...(-0.25))
        )
        
        spawnAndAnimateCubeWithCurvedPath(from: spawnPoint, to: targetPoint, sphereCenter: sphereCenter, sphereRadius: sphereRadius)
    }
    
    private func generateRandomPointOnSphere(center: SIMD3<Float>, radius: Float) -> SIMD3<Float> {
        let theta = Float.random(in: 0...Float.pi * 2)
        let phi = Float.random(in: 0...Float.pi)
        
        let x = radius * sin(phi) * cos(theta)
        let y = radius * sin(phi) * sin(theta)
        let z = radius * cos(phi)
        
        return SIMD3<Float>(
            center.x + x,
            center.y + y,
            center.z + z
        )
    }
    
    private func spawnAndAnimateCubeWithCurvedPath(from start: SIMD3<Float>, to end: SIMD3<Float>, sphereCenter: SIMD3<Float>, sphereRadius: Float) {
        guard let root = rootEntity else { return }
        
        // Create cube
        let cube = ModelEntity(
            mesh: .generateBox(size: 0.02),
            materials: [SimpleMaterial(color: UIColor(red: 0, green: 1, blue: 0, alpha: 1), isMetallic: true)]
        )
        
        // Set initial position
        cube.position = start
        
        // Add collision and input target components
        cube.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: [0.02, 0.02, 0.02])])
        cube.components[InputTargetComponent.self] = InputTargetComponent()
        
        root.addChild(cube)
        
        // Calculate the path parameters
        let distance = length(end - start)
        let arcHeight = distance * 0.375 / 2.0
        let slalomWidth = distance * 0.2 / 2.0
        
        // Increase number of steps for smoother motion
        let numSteps = 120
        let totalDuration: TimeInterval = 1.0
        let stepDuration = totalDuration / Double(numSteps)
        
        // Pre-calculate all positions
        var positions: [SIMD3<Float>] = []
        for i in 0...numSteps {
            let p = Float(i) / Float(numSteps)
            
            // Base linear interpolation with guaranteed end position
            let basePoint = mix(start, end, t: p)
            
            // Height curve (parabolic)
            let heightProgress = 1.0 - pow(p * 2.0 - 1.0, 2)
            let height = arcHeight * heightProgress
            
            // Side-to-side motion (sine wave)
            let sideOffset = sin(p * .pi * 1.5) * slalomWidth * (1.0 - p) // Fade out slalom near end
            
            // Calculate position
            let position = basePoint + SIMD3<Float>(sideOffset, height, 0)
            
            // Ensure final position is exactly the target
            if i == numSteps {
                positions.append(end)
            } else {
                positions.append(position)
            }
        }
        
        // Single animation through all positions
        for i in 0..<positions.count {
            let startDelay = Double(i) * stepDuration
            
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                var transform = cube.transform
                transform.translation = positions[i]
                
                cube.move(
                    to: transform,
                    relativeTo: nil,
                    duration: stepDuration,
                    timingFunction: .linear
                )
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    CurvedPathView()
        .environment(AppModel())
}
