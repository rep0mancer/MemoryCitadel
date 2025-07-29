import Combine
import Foundation
import SwiftUI

/// View model for managing memory rooms within a wing. Provides
/// search, add, archive and delete operations. Notifies the view of
/// errors through the `alertError` publisher.
@MainActor
public final class MemoryListVM: ObservableObject {
    @Published public private(set) var rooms: [MemoryRoom] = []
    @Published public var alertError: CitadelError?
    @Published public var searchText: String = ""

    private let wing: Wing
    private let repository: MemoryRepository

    public init(wing: Wing,
                repository: MemoryRepository = CoreDataMemoryRepository()) {
        self.wing = wing
        self.repository = repository
    }

    public func refresh() async {
        let allRooms = wing.rooms ?? []
        let filtered = allRooms.filter { !$0.isArchived }
        let sorted = filtered.sorted { $0.createdAt < $1.createdAt }
        if searchText.isEmpty {
            rooms = sorted
        } else {
            let lowercased = searchText.lowercased()
            rooms = sorted.filter { $0.title.lowercased().contains(lowercased) || ($0.detail?.lowercased().contains(lowercased) ?? false) }
        }
    }

    public func addRoom(title: String, detail: String?, date: Date?, attachments: Data?) async {
        do {
            _ = try await repository.createRoom(in: wing, title: title, detail: detail, date: date, attachments: attachments)
            await refresh()
        } catch let error as CitadelError {
            alertError = error
        } catch {
            alertError = CitadelError.unknown
        }
    }

    public func archiveRoom(_ room: MemoryRoom) async {
        do {
            try await repository.archiveRoom(room)
            await refresh()
        } catch let error as CitadelError {
            alertError = error
        } catch {
            alertError = CitadelError.unknown
        }
    }

    public func deleteRoom(_ room: MemoryRoom) async {
        do {
            try await repository.deleteRoom(room)
            await refresh()
        } catch let error as CitadelError {
            alertError = error
        } catch {
            alertError = CitadelError.unknown
        }
    }
}
