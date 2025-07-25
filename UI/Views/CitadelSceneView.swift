import SwiftUI
import SceneKit

/// Wraps an `SCNView` for use within SwiftUI. Displays a 3D scene
/// managed by `CitadelSceneVM` and bridges pinch and pan gestures to
/// camera adjustments. When the view appears it subscribes to
/// changes in the view model's scene.
struct CitadelSceneView: UIViewRepresentable {
    @ObservedObject private var viewModel: CitadelSceneVM

    init(viewModel: CitadelSceneVM = CitadelSceneVM()) {
        self.viewModel = viewModel
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor.systemBackground
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.scene = viewModel.scene
        // Gesture recognisers
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(pinch)
        scnView.addGestureRecognizer(pan)
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if uiView.scene !== viewModel.scene {
            uiView.scene = viewModel.scene
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    /// Coordinator handles gesture recognition and communicates
    /// adjustments to the SceneKit camera.
    class Coordinator: NSObject {
        private let viewModel: CitadelSceneVM
        private var lastScale: CGFloat = 1.0
        private var lastTranslation: CGPoint = .zero

        init(viewModel: CitadelSceneVM) {
            self.viewModel = viewModel
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView,
                  let cameraNode = scnView.scene?.rootNode.childNodes.first(where: { $0.camera != nil }) else { return }
            switch gesture.state {
            case .began:
                lastScale = CGFloat(cameraNode.camera?.orthographicScale ?? 40)
            case .changed:
                let scale = lastScale / gesture.scale
                cameraNode.camera?.orthographicScale = max(10, min(100, Double(scale)))
            default:
                break
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView,
                  let cameraNode = scnView.scene?.rootNode.childNodes.first(where: { $0.camera != nil }) else { return }
            let translation = gesture.translation(in: gesture.view)
            switch gesture.state {
            case .began:
                lastTranslation = .zero
            case .changed:
                let deltaX = Float(translation.x - lastTranslation.x)
                let deltaY = Float(translation.y - lastTranslation.y)
                // Adjust camera position; invert y for natural feel
                cameraNode.position.x -= deltaX * 0.1
                cameraNode.position.z -= deltaY * 0.1
                lastTranslation = translation
            default:
                break
            }
        }
    }
}

struct CitadelSceneView_Previews: PreviewProvider {
    static var previews: some View {
        CitadelSceneView()
            .frame(height: 300)
    }
}