import SwiftUI

/// Displays a list of memory palaces. Users can create, select or
/// delete palaces. When the free tier limit is reached tapping the
/// add button will trigger the paywall error published by the view
/// model.
struct PalaceListView: View {
    @StateObject private var viewModel = PalaceListVM()
    @State private var showAddSheet = false
    @State private var newPalaceName: String = ""

    var body: some View {
        List {
            ForEach(viewModel.palaces) { palace in
                NavigationLink(destination: WingListView(palace: palace)) {
                    VStack(alignment: .leading) {
                        Text(palace.name)
                            .font(.headline)
                        Text("\(palace.wings?.count ?? 0) wings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        let palace = viewModel.palaces[index]
                        await viewModel.deletePalace(palace)
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
        .navigationBarItems(trailing: Button(action: {
            showAddSheet = true
        }, label: {
            Image(systemName: "plus")
        }))
        .sheet(isPresented: $showAddSheet) {
            NavigationView {
                Form {
                    Section(header: Text("New Palace")) {
                        TextField("Name", text: $newPalaceName)
                    }
                }
                .navigationTitle(Text("Add Palace"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddSheet = false
                            newPalaceName = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let trimmed = newPalaceName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            Task {
                                await viewModel.addPalace(name: trimmed)
                                newPalaceName = ""
                                showAddSheet = false
                            }
                        }
                        .disabled(newPalaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}

struct PalaceListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PalaceListView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environmentObject(PurchaseManager())
        }
    }
}
