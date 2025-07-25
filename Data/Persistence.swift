import CoreData
import Foundation

/// The `PersistenceController` encapsulates the Core Data stack for the
/// application. It configures an `NSPersistentCloudKitContainer` to
/// automatically sync data across devices via CloudKit. For unit
/// testing and SwiftUI previews an in‑memory store can be used.
struct PersistenceController {
    /// A shared instance used throughout the application.
    static let shared: PersistenceController = PersistenceController()

    /// A preview instance that uses an in‑memory store. This is useful
    /// for SwiftUI previews and tests where persisting data to disk is
    /// undesirable.
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Preload some sample data for previews. This section can be
        // expanded to create sample palaces, wings and rooms.
        let viewContext = controller.container.viewContext
        let palace = MemoryPalace(context: viewContext)
        palace.id = UUID()
        palace.name = "Preview Palace"
        palace.createdAt = Date()
        palace.updatedAt = Date()
        do {
            try viewContext.save()
        } catch {
            assertionFailure("Failed to save preview context: \(error)")
        }
        return controller
    }()

    /// The underlying `NSPersistentCloudKitContainer` which manages
    /// persistent stores and the CloudKit integration. The model name
    /// must match the name of the `.xcdatamodeld` file.
    let container: NSPersistentCloudKitContainer

    /// Creates a new persistence controller. When `inMemory` is true
    /// data is stored only in RAM. When false, data is persisted to
    /// disk and synchronised with CloudKit.
    /// - Parameter inMemory: whether to create an in‑memory store.
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Model")
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            description.cloudKitContainerOptions = nil
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Convert the error into a CitadelError and log it; in
                // production we might display an alert. Here we crash
                // deliberately because persistent store loading is
                // fundamental to the app running correctly.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Saves any changes in the view context to the persistent store.
    /// Errors are mapped to `CitadelError.coreData`. Callers should
    /// handle thrown errors appropriately.
    func saveContext() throws {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            throw CitadelError.coreData(error)
        }
    }
}
