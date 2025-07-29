import CoreData
import Foundation

/// Represents a single attachment linked to a memory room.
public struct RoomAttachment: Codable, Identifiable, Hashable {
    public let id: UUID
    public let fileURLData: Data // Storing bookmark data for the URL
    public var fileName: String

    public init(fileURL: URL) throws {
        self.id = UUID()
        self.fileName = fileURL.lastPathComponent
        self.fileURLData = try fileURL.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
    }
}

/// Represents a single memory cue within a wing. Each room can
/// optionally be scheduled by date and hold arbitrary attachments
/// encoded as a JSON array of file URLs. Rooms can be archived
/// softly via the `isArchived` flag; the purge is handled by a
/// background task.
@objc(MemoryRoom)
public class MemoryRoom: NSManagedObject, Identifiable, Codable {
    // MARK: - Properties

    /// Unique identifier for the room.
    @NSManaged public var id: UUID

    /// The title of the room.
    @NSManaged public var title: String

    /// Optional detailed description or cue. May be `nil`.
    @NSManaged public var detail: String?

    /// Optional scheduling date. If set, reminders could be scheduled.
    @NSManaged public var date: Date?

    /// Encoded attachments. This field stores raw binary data,
    /// expected to be a JSON array of file URL strings.
    @NSManaged public var attachments: Data?

    /// Back reference to the owning wing.
    @NSManaged public var wing: Wing

    /// Temporarily stores the decoded parent wing identifier so the
    /// relationship can be resolved after decoding.
    public var decodedWingID: UUID?

    /// When true the room is considered archived and will be hidden
    /// from the UI. A background purge will permanently delete it.
    @NSManaged public var isArchived: Bool

    /// Timestamp of creation.
    @NSManaged public var createdAt: Date

    /// Timestamp of last update.
    @NSManaged public var updatedAt: Date

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
        updatedAt = Date()
        isArchived = false
    }

    /// Generates a fetch request for `MemoryRoom` entities.
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MemoryRoom> {
        return NSFetchRequest<MemoryRoom>(entityName: "MemoryRoom")
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, title, detail, date, attachments, createdAt, updatedAt, isArchived
        case wingID
    }

    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[.context] as? NSManagedObjectContext else {
            throw CitadelError.procedural("Failed to decode MemoryRoom: missing context")
        }
        guard let entity = NSEntityDescription.entity(forEntityName: "MemoryRoom", in: context) else {
            throw CitadelError.procedural("Failed to decode MemoryRoom: missing entity description")
        }
        self.init(entity: entity, insertInto: context)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        detail = try container.decodeIfPresent(String.self, forKey: .detail)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        attachments = try container.decodeIfPresent(Data.self, forKey: .attachments)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isArchived = try container.decode(Bool.self, forKey: .isArchived)
        // The wing relationship is resolved after decoding. Decode the
        // identifier optionally so missing keys don't cause a failure and
        // store it temporarily for later resolution.
        decodedWingID = try container.decodeIfPresent(UUID.self, forKey: .wingID)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(detail, forKey: .detail)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(attachments, forKey: .attachments)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(wing.id, forKey: .wingID)
    }
}
