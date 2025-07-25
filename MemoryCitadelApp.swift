import SwiftUI

/// The entry point for the Memory Citadel application. This struct
/// configures the top‑level environment objects and renders the
/// primary navigation container. The application is configured to
/// support iOS 15+ in portrait and landscape orientations. All
/// strings are loaded via localisation and the current theme is
/// provided through the environment.
@main
struct MemoryCitadelApp: App {
    /// The shared persistence controller used throughout the app. This
    /// instance manages a Core Data store backed by CloudKit and
    /// exposes a viewContext for use in SwiftUI.
    private let persistenceController = PersistenceController.shared

    /// The purchase manager responsible for managing user entitlements
    /// and handling StoreKit subscription events.
    @StateObject private var purchaseManager = PurchaseManager()

    /// The global app theme. This is persisted using `AppStorage` so the
    /// user's choice is stored across launches.
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(purchaseManager)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
