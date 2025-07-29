import SwiftUI
import UIKit

/// Simple paywall explaining premium benefits and offering a purchase button.
struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Binding var isPresented: Bool
    @State private var isPurchasing = false
    @State private var alertError: CitadelError?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Unlock Premium")
                    .font(.largeTitle).bold()
                Text("Create unlimited palaces and access future features. Your memories stay synced via iCloud.")
                    .multilineTextAlignment(.center)
                Button(action: {
                    HapticManager.impact(.medium)
                    Task {
                        isPurchasing = true
                        defer { isPurchasing = false }
                        do {
                            try await purchaseManager.purchasePremium()
                            isPresented = false
                        } catch let error as CitadelError {
                            alertError = error
                        } catch {
                            alertError = .purchase(error)
                        }
                    }
                }) {
                    if isPurchasing {
                        ProgressView()
                    } else {
                        Text("Subscribe")
                            .font(.headline)
                    }
                }
                Button("Not Now") { isPresented = false }
            }
            .padding()
            .navigationTitle(Text("Premium"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
        .alert(item: $alertError) { error in
            Alert(title: Text(error.errorDescription ?? "Error"))
        }
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView(isPresented: .constant(true))
            .environmentObject(PurchaseManager())
    }
}
