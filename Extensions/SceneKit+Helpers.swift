import SceneKit

/// SceneKit helper extensions used by the Memory Citadel app.
public extension SCNNode {
    /// Applies a radial impulse to the physics body of this node. This
    /// can be used when deleting a memory room to create a small
    /// explosion effect. If the node does not have a physics body one
    /// is added temporarily.
    /// - Parameter magnitude: the strength of the impulse.
    func applyRadialImpulse(magnitude: CGFloat = 5.0) {
        if physicsBody == nil {
            physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        }
        let impulse = SCNVector3(
            Float.random(in: -1...1) * Float(magnitude),
            Float.random(in: 0.5...1.5) * Float(magnitude),
            Float.random(in: -1...1) * Float(magnitude)
        )
        physicsBody?.applyForce(impulse, asImpulse: true)
    }

    /// Fades the node in by animating its opacity from 0 to 1. This is
    /// useful when adding new rooms to the scene.
    /// - Parameter duration: the time over which the fade occurs.
    func fadeIn(duration: TimeInterval = 0.3) {
        opacity = 0
        let action = SCNAction.fadeIn(duration: duration)
        runAction(action)
    }
}