import XCTest
import StoreKit
import StoreKitTest
@testable import MemoryCitadel

/// Tests for the PurchaseManager using a mocked StoreKit environment.
/// A StoreKitTest session simulates transactions so methods can be
/// exercised without real network calls.
final class PurchaseManagerTests: XCTestCase {
    var session: SKTestSession!

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "TestConfiguration")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
    }

    override func tearDownWithError() throws {
        session = nil
    }

    /// Buying the premium product should grant the premium entitlement
    /// once `updateEntitlement()` processes the transaction.
    func testUpdateEntitlementPremium() async throws {
        try session.buyProduct(identifier: "citadel.premium")
        let manager = PurchaseManager()
        await manager.updateEntitlement()
        XCTAssertEqual(manager.entitlement, .premium)
    }

    /// The purchase flow should set the entitlement to premium on
    /// success.
    func testPurchasePremiumUpdatesEntitlement() async throws {
        let manager = PurchaseManager()
        try await manager.purchasePremium()
        XCTAssertEqual(manager.entitlement, .premium)
    }
}
