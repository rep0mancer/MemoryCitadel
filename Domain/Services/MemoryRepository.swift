import CoreData
import Foundation

/// Protocol describing the persistence operations available to the
/// application. The repository abstracts away Core Data specifics and
/// returns model objects. All methods are async and throw a
/// `CitadelError` on failure.
@MainActor
public protocol MemoryRepository {
    func fetchPalaces() async throws -> [MemoryPalace]
    func createPalace(name: String) async throws -> MemoryPalace
    func deletePalace(_ palace: MemoryPalace) async throws

    func createWing(in palace: MemoryPalace, title: String) async throws -> Wing
    func deleteWing(_ wing: Wing) async throws

    func createRoom(in wing: Wing, title: String, detail: String?, date: Date?, attachments: Data?) async throws -> MemoryRoom
    func archiveRoom(_ room: MemoryRoom) async throws
    func deleteRoom(_ room: MemoryRoom) async throws
    func purgeArchivedRooms() async throws
    func fetchRoom(id: UUID) async throws -> MemoryRoom?
}


/// Concrete implementation of `MemoryRepository` backed by Core Data. It
/// ensures operations are performed on the correct context and
/// converts underlying errors to `CitadelError`.
public final class CoreDataMemoryRepository: MemoryRepository {
    private let persistenceController: PersistenceController
    private let purchaseManager: PurchaseManager

    /// Creates a new repository.
    /// - Parameters:
    ///   - persistenceController: the persistence stack
    ///   - purchaseManager: used to enforce entitlement limits
    public init(persistenceController: PersistenceController = .shared,
                purchaseManager: PurchaseManager = PurchaseManager()) {
        self.persistenceController = persistenceController
        self.purchaseManager = purchaseManager
    }

    /// Fetches all palaces sorted by creation date. For the free tier
    /// only the first palace is visible.
    public func fetchPalaces() async throws -> [MemoryPalace] {
        let request: NSFetchRequest<MemoryPalace> = MemoryPalace.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(MemoryPalace.createdAt), ascending: true)
        request.sortDescriptors = [sort]
        do {
            let palaces = try persistenceController.container.viewContext.fetch(request)
            // Enforce free tier limitation: only show first palace
            if purchaseManager.entitlement == .free {
                return Array(palaces.prefix(1))
            } else {
                return palaces
            }
        } catch {
            throw CitadelError.coreData(error)
        }
    }

    /// Creates a new memory palace. Enforces free tier limitation by
    /// throwing if the user tries to create a second palace without a
    /// subscription.
    public func createPalace(name: String) async throws -> MemoryPalace {
        // Enforce entitlement: free tier can create only one palace.
        let existing = try await fetchPalaces()
        if purchaseManager.entitlement == .free && !existing.isEmpty {
            throw CitadelError.procedural(NSLocalizedString("Unlock premium to create more palaces.", comment: "Paywall"))
        }
        let context = persistenceController.container.viewContext
        let palace = MemoryPalace(context: context)
        palace.name = name
        palace.updatedAt = Date()
        do {
            try persistenceController.saveContext()
            return palace
        } catch {
            throw error
        }
    }

    /// Deletes a palace and cascades deletion to its children.
    public func deletePalace(_ palace: MemoryPalace) async throws {
        let context = persistenceController.container.viewContext
        context.delete(palace)
        do {
            try persistenceController.saveContext()
        } catch {
            throw error
        }
    }

    public func createWing(in palace: MemoryPalace, title: String) async throws -> Wing {
        let context = persistenceController.container.viewContext
        let wing = Wing(context: context)
        wing.title = title
        wing.palace = palace
        wing.updatedAt = Date()
        do {
            try persistenceController.saveContext()
            return wing
        } catch {
            throw error
        }
    }

    public func deleteWing(_ wing: Wing) async throws {
        let context = persistenceController.container.viewContext
        context.delete(wing)
        do {
            try persistenceController.saveContext()
        } catch {
            throw error
        }
    }

    public func createRoom(in wing: Wing, title: String, detail: String?, date: Date?, attachments: Data?) async throws -> MemoryRoom {
        let context = persistenceController.container.viewContext
        let room = MemoryRoom(context: context)
        room.title = title
        room.detail = detail
        room.date = date
        room.attachments = attachments
        room.wing = wing
        room.updatedAt = Date()
        do {
            try persistenceController.saveContext()
            return room
        } catch {
            throw error
        }
    }

    /// Soft deletes a room by setting its `isArchived` flag. A
    /// background purge task should remove archived rooms permanently.
    public func archiveRoom(_ room: MemoryRoom) async throws {
        room.isArchived = true
        room.updatedAt = Date()
        do {
            try persistenceController.saveContext()
        } catch {
            throw error
        }
    }

    /// Physically deletes a room from the persistent store. Use with
    /// caution; consider calling `archiveRoom` instead.
    public func deleteRoom(_ room: MemoryRoom) async throws {
        let context = persistenceController.container.viewContext
        context.delete(room)
        do {
            try persistenceController.saveContext()
        } catch {
            throw error
        }
    }

    /// Purges all rooms that have been marked as archived.
    public func purgeArchivedRooms() async throws {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = MemoryRoom.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isArchived == YES")

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try persistenceController.saveContext()
        } catch {
            throw CitadelError.coreData(error)
        }
    }

    public func fetchRoom(id: UUID) async throws -> MemoryRoom? {
        let request: NSFetchRequest<MemoryRoom> = MemoryRoom.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        do {
            let result = try persistenceController.container.viewContext.fetch(request)
            return result.first
        } catch {
            throw CitadelError.coreData(error)
        }
    }
}

extension CoreDataMemoryRepository {
    /// Links decoded rooms to their parent wings based on the
    /// `decodedWingID` property.
    /// - Parameters:
    ///   - rooms: The rooms that were decoded from JSON.
    ///   - wings: The available wings to attach to.
    func attach(decoded rooms: [MemoryRoom], to wings: [Wing]) {
        let mapping = Dictionary(uniqueKeysWithValues: wings.map { ($0.id, $0) })
        for room in rooms {
            if let id = room.decodedWingID, let wing = mapping[id] {
                room.wing = wing
            }
        }
    }

    /// Links decoded wings to their parent palaces based on the
    /// `decodedPalaceID` property.
    /// - Parameters:
    ///   - wings: The wings that were decoded from JSON.
    ///   - palaces: The available palaces to attach to.
    func attach(decoded wings: [Wing], to palaces: [MemoryPalace]) {
        let mapping = Dictionary(uniqueKeysWithValues: palaces.map { ($0.id, $0) })
        for wing in wings {
            if let id = wing.decodedPalaceID, let palace = mapping[id] {
                wing.palace = palace
            }
        }
    }
}
