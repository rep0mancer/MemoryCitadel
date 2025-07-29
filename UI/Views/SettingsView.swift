import SwiftUI
import UIKit

/// Presents application settings including subscription status and
/// theme selection. Users can upgrade to the premium tier via a
/// purchase button which triggers StoreKit and updates the
/// `PurchaseManager`.
struct SettingsView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var isPurchasing: Bool = false
    @State private var alertError: CitadelError?
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
                        HapticManager.impact(.medium)
                        Task {
                            isPurchasing = true
                            defer { isPurchasing = false }
                            do {
                                try await purchaseManager.purchasePremium()
                            } catch let error as CitadelError {
                                // Assign the error to trigger the alert
                                self.alertError = error
                            } catch {
                                // Wrap the unknown error and assign it
                                self.alertError = .purchase(error)
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
                    Button("Restore Purchases") {
                        Task {
                            do {
                                try await purchaseManager.restorePurchases()
                            } catch {
                                self.alertError = .purchase(error)
                            }
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
        .alert(item: $alertError) { error in
            Alert(
                title: Text("Purchase Failed"),
                message: Text(error.errorDescription ?? "An unknown error occurred."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(PurchaseManager())
    }
}
