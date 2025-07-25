import SwiftUI

/// The entry point for the Memory Citadel application. This struct
/// configures the top‑level environment objects and renders the
/// primary navigation container. The application is configured to
/// support iOS 15+ in portrait and landscape orientations. All
/// strings are loaded via localisation and the current theme is
/// provided through the environment.
@main
struct MemoryCitadelApp: App {
  /// The persistence controller used throughout the app. When the
  /// `-ui-testing` launch argument is present an in-memory store with
  /// sample data is injected to keep UI tests deterministic.
  private let persistenceController: PersistenceController

  /// Creates the application instance. The persistence controller is
  /// selected based on launch arguments so UI tests can run in
  /// isolation without CloudKit side effects.
  init() {
      if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
          persistenceController = .preview
      } else {
          persistenceController = .shared
      }
  }

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
