import CoreData
import Foundation

/// Represents the top‑level container in the memory palace hierarchy.
/// A palace can contain zero or more `Wing` objects. Palaces are
/// persisted via Core Data and synchronised through CloudKit.
@objc(MemoryPalace)
public class MemoryPalace: NSManagedObject, Identifiable, Codable {
    // MARK: - Properties

    /// Unique identifier for the palace. Generated on insert.
    @NSManaged public var id: UUID

    /// Human readable name for the palace.
    @NSManaged public var name: String

    /// Creation timestamp. Set when the object is first inserted.
    @NSManaged public var createdAt: Date

    /// Last modification timestamp. Updated whenever a property
    /// changes via the view models or repository.
    @NSManaged public var updatedAt: Date

    /// The collection of wings contained in this palace. The
    /// relationship delete rule is cascade so deleting a palace will
    /// delete all of its wings and associated rooms.
    @NSManaged public var wings: Set<Wing>?

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
        updatedAt = Date()
    }

    /// Generates a fetch request for `MemoryPalace` entities.
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MemoryPalace> {
        return NSFetchRequest<MemoryPalace>(entityName: "MemoryPalace")
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, name, createdAt, updatedAt, wings
    }

    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[.context] as? NSManagedObjectContext else {
            throw CitadelError.procedural("Failed to decode MemoryPalace: missing context")
        }
        // Create entity description and object
        guard let entity = NSEntityDescription.entity(forEntityName: "MemoryPalace", in: context) else {
            throw CitadelError.procedural("Failed to decode MemoryPalace: missing entity description")
        }
        self.init(entity: entity, insertInto: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        wings = try container.decodeIfPresent(Set<Wing>.self, forKey: .wings)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(wings, forKey: .wings)
    }
}