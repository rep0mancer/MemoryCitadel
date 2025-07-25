import Foundation

/// A helper extension to supply an `NSManagedObjectContext` to
/// `Decodable` implementations. When decoding Core Data backed
/// objects, pass the context in the decoder's `userInfo` using this
/// key. See the entity implementations for usage.
public extension CodingUserInfoKey {
    /// The user info key used to specify the managed object context when
    /// decoding Core Data entities. Example:
    ///
    /// ```swift
    /// let decoder = JSONDecoder()
    /// decoder.userInfo[.context] = managedObjectContext
    /// let room = try decoder.decode(MemoryRoom.self, from: data)
    /// ```
    static let context: CodingUserInfoKey = .init(rawValue: "context")!
}
