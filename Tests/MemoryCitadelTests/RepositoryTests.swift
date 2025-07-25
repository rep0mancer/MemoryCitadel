import CoreData
import XCTest
@testable import MemoryCitadel

/// Unit tests for the `CoreDataMemoryRepository`. Uses an in‑memory
/// persistent container to avoid persisting data to disk. These tests
/// verify basic CRUD operations and entitlement enforcement.
final class RepositoryTests: XCTestCase {
    var persistenceController: PersistenceController!
    var repository: CoreDataMemoryRepository!
    var purchaseManager: PurchaseManager!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        purchaseManager = PurchaseManager()
        repository = CoreDataMemoryRepository(persistenceController: persistenceController, purchaseManager: purchaseManager)
    }

    override func tearDown() {
        persistenceController = nil
        repository = nil
        purchaseManager = nil
        super.tearDown()
    }

    func testCreatePalaceRespectsFreeLimit() async throws {
        // Initially no palaces exist
        var palaces = try await repository.fetchPalaces()
        XCTAssertEqual(palaces.count, 0)
        // Create first palace
        let _ = try await repository.createPalace(name: "First")
        palaces = try await repository.fetchPalaces()
        XCTAssertEqual(palaces.count, 1)
        // Attempt to create second palace should throw when entitlement is free
        do {
            let _ = try await repository.createPalace(name: "Second")
            XCTFail("Expected error for exceeding free limit")
        } catch {
            // Expected
        }
    }

    func testCreateWingAndRoom() async throws {
        // Upgrade to premium for unlimited palaces
        purchaseManager.entitlement = .premium
        let palace = try await repository.createPalace(name: "Test Palace")
        let wing = try await repository.createWing(in: palace, title: "East Wing")
        XCTAssertEqual(wing.palace, palace)
        let room = try await repository.createRoom(in: wing, title: "Study", detail: "A quiet corner", date: nil, attachments: nil)
        XCTAssertEqual(room.wing, wing)
        // Fetch the palace again and verify relationships
        let palaces = try await repository.fetchPalaces()
        guard let fetched = palaces.first else { XCTFail("Missing palace"); return }
        XCTAssertEqual(fetched.wings?.count, 1)
        let fetchedWing = fetched.wings?.first
        XCTAssertEqual(fetchedWing?.rooms?.count, 1)
    }

    func testDecodedRoomsAttachToWing() async throws {
        purchaseManager.entitlement = .premium
        let palace = try await repository.createPalace(name: "Import Palace")
        let wingA = try await repository.createWing(in: palace, title: "A")
        let wingB = try await repository.createWing(in: palace, title: "B")

        let iso = ISO8601DateFormatter()
        let date = iso.string(from: Date())
        let json = """
        [
            {
                "id": "\(UUID().uuidString)",
                "title": "Imported",
                "detail": null,
                "date": null,
                "attachments": null,
                "createdAt": "\(date)",
                "updatedAt": "\(date)",
                "isArchived": false,
                "wingID": "\(wingA.id.uuidString)"
            }
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.userInfo[.context] = persistenceController.container.viewContext
        let rooms = try decoder.decode([MemoryRoom].self, from: json)
        repository.attach(decoded: rooms, to: [wingA, wingB])

        XCTAssertEqual(rooms.first?.wing, wingA)
        XCTAssertEqual(wingA.rooms?.contains(rooms.first!), true)
    }
}
