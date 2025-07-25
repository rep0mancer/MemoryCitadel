import Foundation

/// Represents all error cases that can occur within the Memory Citadel
/// application. All async service methods throw `CitadelError` so
/// that callers can handle errors exhaustively and present
/// appropriate alerts to the user. Where possible, underlying errors
/// are captured and carried along for debugging.
public enum CitadelError: Error, LocalizedError, Identifiable {
    case coreData(Error)
    case cloudKit(Error)
    case purchase(Error)
    case procedural(String)
    case unknown

    /// An identifier used by SwiftUI alerts. Conforms to
    /// `Identifiable` so that the alert knows when to re‑present.
    public var id: String {
        switch self {
        case .coreData(let err): return "coreData:\(err.localizedDescription)"
        case .cloudKit(let err): return "cloudKit:\(err.localizedDescription)"
        case .purchase(let err): return "purchase:\(err.localizedDescription)"
        case .procedural(let message): return "procedural:\(message)"
        case .unknown: return "unknown"
        }
    }

    /// A human readable description suitable for alert titles.
    public var errorDescription: String? {
        switch self {
        case .coreData: return NSLocalizedString("A data error occurred.", comment: "CoreData error")
        case .cloudKit: return NSLocalizedString("A sync error occurred.", comment: "CloudKit error")
        case .purchase: return NSLocalizedString("A purchase error occurred.", comment: "Purchase error")
        case .procedural(let message): return message
        case .unknown: return NSLocalizedString("An unknown error occurred.", comment: "Unknown error")
        }
    }

    /// Provides the underlying error if available. This can be used
    /// for logging and debugging.
    public var underlyingError: Error? {
        switch self {
        case .coreData(let err), .cloudKit(let err), .purchase(let err): return err
        default: return nil
        }
    }
}