import CoreData
import Foundation

/// Represents a wing inside a memory palace. Wings group
/// `MemoryRoom` instances and are children of a `MemoryPalace`.
@objc(Wing)
public class Wing: NSManagedObject, Identifiable, Codable {
    // MARK: - Properties

    /// Unique identifier for the wing. Generated on insert.
    @NSManaged public var id: UUID

    /// A short title used to label this wing.
    @NSManaged public var title: String

    /// Timestamp of creation.
    @NSManaged public var createdAt: Date

    /// Timestamp of last update.
    @NSManaged public var updatedAt: Date

    /// Back reference to the owning memory palace. This is the inverse
    /// of the `wings` relationship defined on `MemoryPalace`.
    @NSManaged public var palace: MemoryPalace

    /// Collection of rooms contained within this wing. Delete rule
    /// cascade ensures rooms are removed when the wing is deleted.
    @NSManaged public var rooms: Set<MemoryRoom>?

    /// Temporarily stores the decoded parent palace identifier so
    /// the relationship can be resolved after decoding.
    public var decodedPalaceID: UUID?

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
        updatedAt = Date()
    }

    /// Generates a fetch request for `Wing` entities.
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Wing> {
        return NSFetchRequest<Wing>(entityName: "Wing")
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, title, createdAt, updatedAt, rooms
        case palaceID
    }

    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[.context] as? NSManagedObjectContext else {
            throw CitadelError.procedural("Failed to decode Wing: missing context")
        }
        guard let entity = NSEntityDescription.entity(forEntityName: "Wing", in: context) else {
            throw CitadelError.procedural("Failed to decode Wing: missing entity description")
        }
        self.init(entity: entity, insertInto: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        rooms = try container.decodeIfPresent(Set<MemoryRoom>.self, forKey: .rooms)
        // The palace relationship is resolved outside of decoding. Decode the
        // identifier optionally so decoding doesn't fail if the key is missing
        // and store it temporarily for later resolution.
        decodedPalaceID = try container.decodeIfPresent(UUID.self, forKey: .palaceID)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(rooms, forKey: .rooms)
        try container.encode(palace.id, forKey: .palaceID)
    }
}
