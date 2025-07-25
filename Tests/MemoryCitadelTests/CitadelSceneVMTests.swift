import XCTest
@testable import MemoryCitadel

/// Tests that the `CitadelSceneVM` automatically reloads its scene when
/// rooms are added or removed from the repository.
final class CitadelSceneVMTests: XCTestCase {
    var persistenceController: PersistenceController!
    var repository: CoreDataMemoryRepository!
    var purchaseManager: PurchaseManager!
    var viewModel: CitadelSceneVM!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        purchaseManager = PurchaseManager()
        repository = CoreDataMemoryRepository(persistenceController: persistenceController,
                                              purchaseManager: purchaseManager)
        viewModel = CitadelSceneVM(repository: repository,
                                   context: persistenceController.container.viewContext)
    }

    override func tearDown() {
        persistenceController = nil
        repository = nil
        purchaseManager = nil
        viewModel = nil
        super.tearDown()
    }

    private func buildingCount() -> Int {
        viewModel.scene.rootNode.childNodes.filter { $0.name?.hasPrefix("Building_") == true }.count
    }

    func testSceneReloadsAfterAddingRoom() async throws {
        purchaseManager.entitlement = .premium
        let palace = try await repository.createPalace(name: "Test")
        let wing = try await repository.createWing(in: palace, title: "Wing")
        // Wait for initial load
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(buildingCount(), 0)
        _ = try await repository.createRoom(in: wing, title: "Room", detail: nil, date: nil, attachments: nil)
        // Give the view model some time to receive the notification and reload
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(buildingCount(), 1)
    }
}
