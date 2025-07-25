import SwiftUI

/// Presents application settings including subscription status and
/// theme selection. Users can upgrade to the premium tier via a
/// purchase button which triggers StoreKit and updates the
/// `PurchaseManager`.
struct SettingsView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var isPurchasing: Bool = false
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    var body: some View {
        Form {
            Section(header: Text("Subscription")) {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(purchaseManager.entitlement == .premium ? NSLocalizedString("Premium", comment: "Premium status") : NSLocalizedString("Free", comment: "Free status"))
                        .foregroundColor(purchaseManager.entitlement == .premium ? .green : .primary)
                }
                if purchaseManager.entitlement == .free {
                    Button(action: {
                        Task {
                            isPurchasing = true
                            defer { isPurchasing = false }
                            do {
                                try await purchaseManager.purchasePremium()
                            } catch let error as CitadelError {
                                // The view itself does not present alerts; instead the root view may
                                print("Purchase error: \(error)")
                            } catch {
                                print("Unknown purchase error: \(error)")
                            }
                        }
                    }) {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Unlock Premium")
                        }
                    }
                }
            }

            Section(header: Text("Appearance")) {
                Toggle(isOn: $isDarkMode) {
                    Text("Dark Mode")
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(PurchaseManager())
    }
}
