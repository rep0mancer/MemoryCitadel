import Combine
import Foundation
import SwiftUI

/// View model for listing and managing wings within a given palace.
@MainActor
public final class WingListVM: ObservableObject {
    @Published public private(set) var wings: [Wing] = []
    @Published public var alertError: CitadelError?

    private let palace: MemoryPalace
    private let repository: MemoryRepository

    public init(palace: MemoryPalace,
                repository: MemoryRepository = CoreDataMemoryRepository()) {
        self.palace = palace
        self.repository = repository
    }

    public func refresh() async {
        // Fetch wings from the palace relationship and sort by creation date
        let allWings = palace.wings ?? []
        wings = allWings.sorted(by: { $0.createdAt < $1.createdAt })
    }

    public func addWing(title: String) async {
        do {
            _ = try await repository.createWing(in: palace, title: title)
            await refresh()
        } catch let error as CitadelError {
            alertError = error
        } catch {
            alertError = CitadelError.unknown
        }
    }

    public func deleteWing(_ wing: Wing) async {
        do {
            try await repository.deleteWing(wing)
            await refresh()
        } catch let error as CitadelError {
            alertError = error
        } catch {
            alertError = CitadelError.unknown
        }
    }
}