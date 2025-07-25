import SwiftUI

/// The root view of the Memory Citadel application. A simple
/// `TabView` provides top‑level navigation between the list of
/// palaces, the 3D citadel scene and the settings screen. The
/// `PalaceListView` itself handles navigation to wings and memory
/// rooms.
struct RootView: View {
    /// The purchase manager used to determine access to premium
    /// features such as additional palaces.
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var body: some View {
        TabView {
            NavigationView {
                PalaceListView()
                    .navigationTitle(Text("Palaces"))
            }
            .tabItem {
                Image(systemName: "building.2.crop.circle")
                Text("Palaces")
            }

            NavigationView {
                CitadelSceneView()
                    .navigationTitle(Text("Citadel"))
            }
            .tabItem {
                Image(systemName: "cube")
                Text("Citadel")
            }

            NavigationView {
                SettingsView()
                    .navigationTitle(Text("Settings"))
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(PurchaseManager())
    }
}
