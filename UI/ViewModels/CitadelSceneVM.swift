import Combine
import Foundation
import SceneKit
import CoreData

/// View model responsible for constructing the 3D citadel scene. It
/// observes the repository for changes and rebuilds the scene when
/// palaces, wings or rooms are added or removed. Nodes are
/// positioned deterministically on a grid based on wing and room
/// indices. The view model publishes an `SCNScene` for the
/// SwiftUI wrapper to display.
@MainActor
public final class CitadelSceneVM: ObservableObject {
    /// The SceneKit scene displayed in the citadel view. Clients
    /// should not mutate this scene directly; instead call `reload()`.
    @Published public private(set) var scene: SCNScene = SCNScene()

    private let repository: MemoryRepository
    private let proceduralFactory: ProceduralFactory
    private let context: NSManagedObjectContext

    /// Holds Combine subscriptions for context change notifications.
    private var cancellables: Set<AnyCancellable> = []

    /// Reference to the currently running reload task.
    private var reloadTask: Task<Void, Never>?

    /// References to the persistent camera and light nodes in the scene.
    private var cameraNode: SCNNode?
    private var lightNode: SCNNode?

    public init(repository: MemoryRepository = CoreDataMemoryRepository(),
                proceduralFactory: ProceduralFactory = ProceduralFactory(),
                context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.repository = repository
        self.proceduralFactory = proceduralFactory
        self.context = context
        // Initialise scene with default camera and lighting
        setupScene()
        // Observe context changes to update the scene automatically
        NotificationCenter.default.publisher(
            for: .NSManagedObjectContextObjectsDidChange,
            object: context
        )
        .sink { [weak self] notification in
            guard let self else { return }
            guard let info = notification.userInfo else { return }
            let keys = [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey]
            for key in keys {
                if let objs = info[key] as? Set<NSManagedObject>,
                   objs.contains(where: { $0 is Wing || $0 is MemoryRoom }) {
                    // Cancel any existing reload task to avoid overlapping work
                    self.reloadTask?.cancel()
                    // Assign and start a new task
                    self.reloadTask = Task {
                        await self.reload()
                    }
                    break
                }
            }
        }
        .store(in: &cancellables)
        Task {
            await reload()
        }
    }

    /// Sets up the base scene with an orthographic camera and default
    /// lighting. The camera uses an isometric perspective defined by
    /// the spec.
    private func setupScene() {
        scene = SCNScene()
        // Camera
        let camNode = SCNNode()
        camNode.camera = SCNCamera()
        camNode.camera?.usesOrthographicProjection = true
        camNode.camera?.orthographicScale = 40
        // Place camera at an isometric angle (45° rotation around Y,
        // 35.264° tilt around X)
        camNode.eulerAngles = SCNVector3(-Float(35.264 * .pi / 180.0), Float(45 * .pi / 180.0), 0)
        camNode.position = SCNVector3(x: 30, y: 30, z: 30)
        scene.rootNode.addChildNode(camNode)
        cameraNode = camNode
        // Lighting
        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .ambient
        light.light?.intensity = 1000
        scene.rootNode.addChildNode(light)
        lightNode = light
    }

    /// Reloads the scene by removing existing building nodes and
    /// generating new ones for each non‑archived room in every wing.
    public func reload() async {
        // Remove all existing child nodes except the persistent camera and light
        for child in scene.rootNode.childNodes where child !== cameraNode && child !== lightNode {
            child.removeFromParentNode()
        }
        do {
            let palaces = try await repository.fetchPalaces()
            var wingIndex = 0
            for palace in palaces {
                guard let wings = palace.wings else { continue }
                for wing in wings.sorted(by: { $0.createdAt < $1.createdAt }) {
                    var roomIndex = 0
                    if let rooms = wing.rooms?.filter({ !$0.isArchived }) {
                        for room in rooms.sorted(by: { $0.createdAt < $1.createdAt }) {
                            let node = proceduralFactory.makeBuildingNode(for: room)
                            // Position on grid: x = wingIndex*50 + (roomIndex mod 10) * 6
                            // z coordinate remains 0 for simplicity
                            let x = Double(wingIndex) * 50.0 + Double(roomIndex % 10) * 6.0
                            let z = Double(roomIndex / 10) * 10.0
                            node.position = SCNVector3(x, 0, z)
                            scene.rootNode.addChildNode(node)
                            roomIndex += 1
                        }
                    }
                    wingIndex += 1
                }
            }
        } catch {
            // Log but don't crash; the scene will simply be empty
            print("Failed to reload scene: \(error)")
        }
    }
}
