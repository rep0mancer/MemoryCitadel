import Combine
import Foundation
import StoreKit

/// Represents the user's access level within the Memory Citadel app.
/// The free tier restricts the number of palaces to one. The
/// premium tier unlocks unlimited palaces and other future features.
public enum Entitlement: String {
    case free
    case premium
}

/// Manages StoreKit purchases and publishes entitlement changes.
/// This class observes the transaction updates stream to detect
/// renewals, revocations and expirations. It also provides a method
/// for initiating a purchase of the premium subscription.
@MainActor
public final class PurchaseManager: ObservableObject {
    /// The current entitlement of the user. Changing this value will
    /// update subscribed view models and cause UI to refresh.
    @Published public private(set) var entitlement: Entitlement = .free

    /// A cancellable used to maintain the lifetime of the transaction
    /// updates task.
    private var updatesTask: Task<Void, Never>?

    public init() {
        // Start observing transaction updates as soon as the manager
        // is created. This listens for revoked, expired or renewed
        // subscriptions.
        updatesTask = Task {
            await observeTransactionUpdates()
        }
        // Immediately refresh entitlements
        Task {
            await updateEntitlement()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    /// Refreshes the user's entitlements by checking the current
    /// subscription status. If a premium subscription is active the
    /// entitlement is set accordingly.
    public func updateEntitlement() async {
        do {
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if transaction.productID == "citadel.premium" {
                        entitlement = .premium
                        return
                    }
                default:
                    continue
                }
            }
            // No premium entitlement found
            entitlement = .free
        } catch {
            // In case of failure (e.g. network) assume free tier
            entitlement = .free
        }
    }

    /// Initiates a purchase of the premium subscription. On success
    /// the entitlement is updated. Throws a `CitadelError.purchase` on
    /// failure for the caller to handle.
    public func purchasePremium() async throws {
        do {
            // Request product from StoreKit
            let storeProducts = try await Product.products(for: ["citadel.premium"])
            guard let premium = storeProducts.first else {
                throw CitadelError.purchase(StoreError.productNotFound)
            }
            // Begin the purchase flow
            let result = try await premium.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                // Upgrade entitlement
                entitlement = .premium
                await transaction.finish()
            case .userCancelled:
                // Do nothing; user cancelled
                break
            case .pending:
                // Payment is pending; entitlement remains unchanged
                break
            @unknown default:
                break
            }
        } catch {
            throw CitadelError.purchase(error)
        }
    }

    /// Observes the continuous transaction updates stream. When a
    /// transaction for the premium subscription is revoked or expires
    /// the entitlement is set back to free. This function runs until
    /// the task is cancelled.
    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            do {
                switch result {
                case .verified(let transaction):
                    if transaction.productID == "citadel.premium" {
                        if transaction.revocationDate != nil || transaction.isUpgraded {
                            entitlement = .free
                        } else {
                            entitlement = .premium
                        }
                    }
                    await transaction.finish()
                default:
                    continue
                }
            } catch {
                // Log transaction failures; do not surface to UI
                continue
            }
        }
    }

    /// Validates a StoreKit transaction.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw CitadelError.purchase(StoreError.unverified)
        case .verified(let safe):
            return safe
        }
    }

    /// Errors that can occur during store operations. These are
    /// converted into `CitadelError.purchase` in public APIs.
    enum StoreError: Error {
        case productNotFound
        case unverified
    }
}