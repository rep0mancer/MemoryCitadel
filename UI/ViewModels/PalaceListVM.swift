import Combine
import Foundation
import SwiftUI

/// View model driving the `PalaceListView`. Responsible for loading
/// palaces from the repository, enforcing entitlement rules and
/// handling creation and deletion. Errors are published via
/// `alertError` for presentation in the UI.
@MainActor
public final class PalaceListVM: ObservableObject {
    @Published public private(set) var palaces: [MemoryPalace] = []
    @Published public var alertError: CitadelError?

    private let repository: MemoryRepository
    private let purchaseManager: PurchaseManager

    public init(repository: MemoryRepository = CoreDataMemoryRepository(),
                purchaseManager: PurchaseManager = .init()) {
        self.repository = repository
        self.purchaseManager = purchaseManager
    }

    /// Loads the list of palaces asynchronously.
    public func refresh() async {
        do {
            palaces = try await repository.fetchPalaces()
        } catch let error as CitadelError {
            alertError = error
        } catch {
            alertError = CitadelError.unknown
        }
    }

    /// Creates a new palace with the given name. If the user exceeds
    /// their entitlement this will throw and present a paywall.
    public func addPalace(name: String) async {
        do {
            _ = try await repository.createPalace(name: name)
            await refresh()
        } catch let error as CitadelError {
            alertError = error
        } catch {
            alertError = CitadelError.unknown
        }
    }

    /// Deletes the specified palace.
    public func deletePalace(_ palace: MemoryPalace) async {
        do {
            try await repository.deletePalace(palace)
            await refresh()
        } catch let error as CitadelError {
            alertError = error
        } catch {
            alertError = CitadelError.unknown
        }
    }
}
