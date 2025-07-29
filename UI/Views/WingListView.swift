import SwiftUI

/// Displays the wings within a specific palace. Users can add new
/// wings and navigate to the list of rooms in each wing.
struct WingListView: View {
    private let palace: MemoryPalace
    @ObservedObject private var viewModel: WingListVM
    @State private var showAddSheet = false
    @State private var newWingTitle: String = ""

    init(palace: MemoryPalace) {
        self.palace = palace
        _viewModel = ObservedObject(wrappedValue: WingListVM(palace: palace))
    }

    var body: some View {
        List {
            if viewModel.wings.isEmpty {
                Text("You have no wings. Tap the '+' to create one.")
                    .foregroundColor(.secondary)
            }
            ForEach(viewModel.wings) { wing in
                NavigationLink(destination: MemoryListView(wing: wing)) {
                    Text(wing.title)
                }
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        let wing = viewModel.wings[index]
                        await viewModel.deleteWing(wing)
                    }
                }
            }
        }
        .onAppear {
            Task { await viewModel.refresh() }
        }
        .alert(item: $viewModel.alertError) { error in
            Alert(title: Text(error.errorDescription ?? "Error"))
        }
        .navigationBarTitle(Text(palace.name), displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            showAddSheet = true
        }) {
            Image(systemName: "plus")
        })
        .sheet(isPresented: $showAddSheet) {
            NavigationView {
                Form {
                    Section(header: Text("New Wing")) {
                        TextField("Title", text: $newWingTitle)
                    }
                }
                .navigationTitle(Text("Add Wing"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddSheet = false
                            newWingTitle = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let trimmed = newWingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            Task {
                                await viewModel.addWing(title: trimmed)
                                newWingTitle = ""
                                showAddSheet = false
                            }
                        }
                        .disabled(newWingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}

struct WingListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let palace = MemoryPalace(context: context)
        palace.name = "Sample Palace"
        return NavigationView {
            WingListView(palace: palace)
                .environmentObject(CitadelSceneVM())
        }
    }
}
