import XCTest
import SceneKit
@testable import MemoryCitadel

/// Tests for the procedural generation factory. Ensures that the
/// geometry produced for a given room is deterministic based on its
/// UUID and that the building structure contains expected child
/// nodes.
final class ProceduralFactoryTests: XCTestCase {
    func testDeterministicGeometry() {
        let context = PersistenceController(inMemory: true).container.viewContext
        let room = MemoryRoom(context: context)
        room.id = UUID(uuidString: "D6A1F47E-9B1F-4E9E-A2A5-123456789ABC")!
        room.title = "Test"
        room.createdAt = Date()
        room.updatedAt = Date()
        let factory = ProceduralFactory()
        let nodeA = factory.makeBuildingNode(for: room, wingIndex: 0)
        let nodeB = factory.makeBuildingNode(for: room, wingIndex: 0)
        XCTAssertEqual(nodeA.childNodes.count, nodeB.childNodes.count)
        for (child1, child2) in zip(nodeA.childNodes, nodeB.childNodes) {
            // Compare geometry types and sizes
            XCTAssertEqual(type(of: child1.geometry!), type(of: child2.geometry!))
            XCTAssertEqual(child1.geometry?.boundingBox.max.y ?? 0, child2.geometry?.boundingBox.max.y ?? 0, accuracy: 0.001)
        }
    }
}
