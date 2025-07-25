import XCTest
import SceneKit
@testable import MemoryCitadel

/// Tests for the procedural generation factory. Ensures that the
/// geometry produced for a given room is deterministic based on a
/// hash-derived seed of its UUID and that the building structure
/// contains expected child nodes.
final class ProceduralFactoryTests: XCTestCase {
    func testDeterministicGeometry() {
        let context = PersistenceController(inMemory: true).container.viewContext
        let room = MemoryRoom(context: context)
        room.id = UUID(uuidString: "D6A1F47E-9B1F-4E9E-A2A5-123456789ABC")!
        room.title = "Test"
        room.createdAt = Date()
        room.updatedAt = Date()
        let factory = ProceduralFactory()
        let nodeA = factory.makeBuildingNode(for: room)
        let nodeB = factory.makeBuildingNode(for: room)
        XCTAssertEqual(nodeA.childNodes.count, nodeB.childNodes.count)
        for (child1, child2) in zip(nodeA.childNodes, nodeB.childNodes) {
            // Compare geometry types and sizes
            XCTAssertEqual(type(of: child1.geometry!), type(of: child2.geometry!))
            XCTAssertEqual(child1.geometry?.boundingBox.max.y ?? 0, child2.geometry?.boundingBox.max.y ?? 0, accuracy: 0.001)
        }
    }

    /// Two UUIDs that share the same leading bytes should still produce
    /// different building geometry because the seed is based on the full
    /// UUID digest.
    func testFullUUIDInfluencesSeed() {
        let context = PersistenceController(inMemory: true).container.viewContext

        let room1 = MemoryRoom(context: context)
        room1.id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000001")!
        room1.title = "Test1"
        room1.createdAt = Date()
        room1.updatedAt = Date()

        let room2 = MemoryRoom(context: context)
        room2.id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-000000000002")!
        room2.title = "Test2"
        room2.createdAt = Date()
        room2.updatedAt = Date()

        let factory = ProceduralFactory()
        let nodeA = factory.makeBuildingNode(for: room1)
        let nodeB = factory.makeBuildingNode(for: room2)

        var identical = true
        for (child1, child2) in zip(nodeA.childNodes, nodeB.childNodes) {
            if type(of: child1.geometry!) != type(of: child2.geometry!) {
                identical = false
                break
            }
            if abs((child1.geometry?.boundingBox.max.y ?? 0) - (child2.geometry?.boundingBox.max.y ?? 0)) > 0.0001 {
                identical = false
                break
            }
        }
        XCTAssertFalse(identical, "Buildings should differ when UUIDs differ")
    }
}