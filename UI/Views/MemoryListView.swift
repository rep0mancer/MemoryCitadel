import SwiftUI

/// Lists the memory rooms within a given wing. Rooms can be
/// searched, added, archived and deleted. When a room is archived it
/// disappears from the list; a future purge task will remove it
/// permanently.
struct MemoryListView: View {
    private let wing: Wing
    @ObservedObject private var viewModel: MemoryListVM
    @State private var showAddSheet = false
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var date: Date = Date()
    @State private var includeDate: Bool = false

    init(wing: Wing) {
        self.wing = wing
        _viewModel = ObservedObject(wrappedValue: MemoryListVM(wing: wing))
    }

    var body: some View {
        List {
            ForEach(viewModel.rooms) { room in
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.title)
                        .font(.headline)
                    if let detail = room.detail, !detail.isEmpty {
                        Text(detail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let date = room.date {
                        Text(date, style: .date)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .swipeActions(allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteRoom(room) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        Task { await viewModel.archiveRoom(room) }
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(.orange)
                }
            }
        }
        .navigationTitle(Text(wing.title))
        .searchable(text: $viewModel.searchText)
        .onChange(of: viewModel.searchText) { _ in
            Task { await viewModel.refresh() }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .onAppear {
            Task { await viewModel.refresh() }
        }
        .alert(item: $viewModel.alertError) { error in
            Alert(title: Text(error.errorDescription ?? "Error"))
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Title")) {
                        TextField("Title", text: $title)
                    }
                    Section(header: Text("Detail")) {
                        TextField("Detail", text: $detail)
                    }
                    Section {
                        Toggle(isOn: $includeDate) {
                            Text("Schedule Date")
                        }
                        if includeDate {
                            DatePicker(selection: $date, displayedComponents: [.date]) {
                                Text("Date")
                            }
                        }
                    }
                }
                .navigationTitle(Text("Add Room"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddSheet = false
                            clearInputs()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmedTitle.isEmpty else { return }
                            let optionalDate = includeDate ? date : nil
                            Task {
                                await viewModel.addRoom(title: trimmedTitle, detail: detail.isEmpty ? nil : detail, date: optionalDate)
                                clearInputs()
                                showAddSheet = false
                            }
                        }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    private func clearInputs() {
        title = ""
        detail = ""
        includeDate = false
    }
}

struct MemoryListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let palace = MemoryPalace(context: context)
        palace.name = "Example"
        let wing = Wing(context: context)
        wing.title = "Wing"
        wing.palace = palace
        return NavigationView {
            MemoryListView(wing: wing)
        }
    }
}