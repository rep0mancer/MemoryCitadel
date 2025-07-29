import Foundation
import SceneKit
import GameplayKit

/// Generates deterministic geometry for a memory room. By seeding the
/// random number generator with a value derived from the room's UUID the
/// resulting node will always have the same dimensions, shapes and
/// colours for a given room. Buildings are assembled from simple
/// primitives and composited into a parent node.
public struct ProceduralFactory {
    /// Generates a building node for the given room. The returned
    /// node contains child nodes for the foundation, walls, roof and
    /// optionally a tower flag. All node names are set for easier
    /// debugging.
    /// - Parameter room: the memory room to base the geometry on
    /// - Returns: a root `SCNNode` representing the building
    public func makeBuildingNode(for room: MemoryRoom, wingIndex: Int) -> SCNNode {
        // Seed RNG with a deterministic value derived from the room UUID
        let seed = withUnsafeBytes(of: room.id.uuid) { ptr in
            ptr.load(as: UInt64.self).bigEndian
        }
        let randomSource = GKLinearCongruentialRandomSource(seed: seed)
        let random = GKRandomDistribution(randomSource: randomSource)

        let rootNode = SCNNode()
        rootNode.name = "Building_\(room.id)"

        // Base dimensions
        let width: CGFloat = 4.0
        let length: CGFloat = 4.0

        // Foundation
        let foundationHeight: CGFloat = 0.5
        let foundationGeometry = SCNBox(width: width, height: foundationHeight, length: length, chamferRadius: 0.1)
        foundationGeometry.firstMaterial = triToneMaterial(seed: seed, index: 0, palette: wingIndex)
        let foundationNode = SCNNode(geometry: foundationGeometry)
        foundationNode.position = SCNVector3(0, foundationHeight / 2.0, 0)
        foundationNode.name = "Foundation"
        rootNode.addChildNode(foundationNode)

        // Walls
        let wallHeight: CGFloat = CGFloat(random.nextInt(upperBound: 3) + 1)
        let wallGeometry = SCNBox(width: width * 0.9, height: wallHeight, length: length * 0.9, chamferRadius: 0.05)
        wallGeometry.firstMaterial = triToneMaterial(seed: seed, index: 1, palette: wingIndex)
        let wallNode = SCNNode(geometry: wallGeometry)
        wallNode.position = SCNVector3(0, foundationHeight + wallHeight / 2.0, 0)
        wallNode.name = "Walls"
        rootNode.addChildNode(wallNode)

        // Roof: choose pyramid or flat roof
        let roofStyle = random.nextInt(upperBound: 3)
        let roofHeight: CGFloat = 1.0
        let roofGeometry: SCNGeometry
        if roofStyle == 0 {
            roofGeometry = SCNPyramid(width: width * 0.9, height: roofHeight, length: length * 0.9)
        } else if roofStyle == 1 {
            roofGeometry = SCNBox(width: width * 0.9, height: roofHeight, length: length * 0.9, chamferRadius: 0.0)
        } else {
            roofGeometry = SCNCone(topRadius: 0.0, bottomRadius: max(width, length) * 0.5, height: roofHeight)
        }
        roofGeometry.firstMaterial = triToneMaterial(seed: seed, index: 2, palette: wingIndex)
        let roofNode = SCNNode(geometry: roofGeometry)
        roofNode.position = SCNVector3(0, foundationHeight + wallHeight + roofHeight / 2.0, 0)
        roofNode.name = "Roof"
        rootNode.addChildNode(roofNode)

        // Optional tower flag (random > 0.8)
        let chance = Float(randomSource.nextUniform())
        if chance > 0.8 {
            let poleHeight: CGFloat = 1.2
            let poleGeometry = SCNCylinder(radius: 0.05, height: poleHeight)
            poleGeometry.firstMaterial = triToneMaterial(seed: seed, index: 3, palette: wingIndex)
            let poleNode = SCNNode(geometry: poleGeometry)
            poleNode.position = SCNVector3(0, foundationHeight + wallHeight + roofHeight + poleHeight / 2.0, 0)
            poleNode.name = "TowerPole"
            rootNode.addChildNode(poleNode)

            // Flag (simple plane)
            let flagWidth: CGFloat = 1.0
            let flagHeight: CGFloat = 0.4
            let flagGeometry = SCNPlane(width: flagWidth, height: flagHeight)
            flagGeometry.firstMaterial = triToneMaterial(seed: seed, index: 4, palette: wingIndex)
            let flagNode = SCNNode(geometry: flagGeometry)
            flagNode.position = SCNVector3(flagWidth / 2.0, 0.0, 0)
            flagNode.eulerAngles.y = -.pi / 2
            flagNode.name = "TowerFlag"
            poleNode.addChildNode(flagNode)
        }

        // Decorative trees around the building
        let decoRandom = GKLinearCongruentialRandomSource(seed: seed ^ 0xDEADBEEF)
        let decoDist = GKRandomDistribution(randomSource: decoRandom, lowestValue: 0, highestValue: 2)
        let treeCount = decoDist.nextInt()
        for i in 0..<treeCount {
            let tree = makeTree(palette: wingIndex)
            let angle = Float(Double(i) / Double(max(treeCount,1)) * 2.0 * Double.pi)
            let radius = Float(5.0)
            tree.position = SCNVector3(cos(angle) * radius, 0, sin(angle) * radius)
            rootNode.addChildNode(tree)
        }

        return rootNode
    }

    private func makeTree(palette: Int) -> SCNNode {
        let trunk = SCNCylinder(radius: 0.1, height: 1.0)
        trunk.firstMaterial?.diffuse.contents = UIColor.brown
        let trunkNode = SCNNode(geometry: trunk)
        trunkNode.position.y = 0.5

        let crown = SCNCone(topRadius: 0, bottomRadius: 0.4, height: 0.8)
        let color: UIColor = palette % 2 == 0 ? UIColor.systemTeal : UIColor.systemGreen
        crown.firstMaterial?.diffuse.contents = color
        let crownNode = SCNNode(geometry: crown)
        crownNode.position.y = 1.2

        let tree = SCNNode()
        tree.name = "Tree"
        tree.addChildNode(trunkNode)
        tree.addChildNode(crownNode)
        return tree
    }

    /// Creates a simple material with a tri‑tone ramp based on the seed and
    /// index. This mimics a stylised metal shader with ambient
    /// occlusion baked into the vertex colours. For production you
    /// would implement a custom shader; here we use plain colours.
    private func triToneMaterial(seed: UInt64, index: Int, palette: Int) -> SCNMaterial {
        let material = SCNMaterial()
        let baseHue: CGFloat
        if palette % 2 == 0 {
            // Cool palette around blue
            baseHue = CGFloat((200 + (Int(seed) + index * 23) % 40)) / 360.0
        } else {
            // Warm palette around orange
            baseHue = CGFloat((20 + (Int(seed) + index * 23) % 40)) / 360.0
        }
        let baseColor = UIColor(hue: baseHue, saturation: 0.5, brightness: 0.7, alpha: 1.0)
        material.diffuse.contents = baseColor
        material.specular.contents = UIColor.white.withAlphaComponent(0.3)
        material.locksAmbientWithDiffuse = true
        return material
    }
}
