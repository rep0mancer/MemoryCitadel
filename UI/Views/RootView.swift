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
    @Environment(\.managedObjectContext) private var context

    /// Shared scene view model so other views can trigger animations.
    @StateObject private var citadelViewModel = CitadelSceneVM()

    @State private var selectedTab: Int = 0
    @State private var navigationPath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $navigationPath) {
                PalaceListView()
                    .navigationTitle(Text("Palaces"))
                    .navigationDestination(for: MemoryRoom.self) { room in
                        MemoryRoomDetailView(room: room)
                    }
                    .navigationDestination(for: Wing.self) { wing in
                        MemoryListView(wing: wing)
                    }
            }
            .tabItem {
                Image(systemName: "building.2.crop.circle")
                Text("Palaces")
            }
            .tag(0)
            
            NavigationView {
                CitadelSceneView(viewModel: citadelViewModel) { roomID in
                    Task {
                        let repository = CoreDataMemoryRepository()
                        if let room = try? await repository.fetchRoom(by: roomID) {
                            self.navigationPath.append(room.wing)
                            self.navigationPath.append(room)
                            self.selectedTab = 0
                        }
                    }
                }
                .navigationTitle(Text("Citadel"))
            }
            .tabItem {
                Image(systemName: "cube")
                Text("Citadel")
            }
            .tag(1)

            NavigationView {
                SettingsView()
                    .navigationTitle(Text("Settings"))
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
            .tag(2)
        }
        .environmentObject(citadelViewModel)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(PurchaseManager())
            .environmentObject(CitadelSceneVM())
    }
}
