import SwiftUI
import QuickLook

/// Displays details for a single memory room including its attachments.
struct MemoryRoomDetailView: View {
    @ObservedObject var room: MemoryRoom
    private let repository: MemoryRepository
    @State private var editingTitle: String
    @State private var editingDetail: String
    @State private var isEditing = false
    @State private var previewURL: URL?
    @State private var showPreview = false
    @State private var alertError: CitadelError?

    init(room: MemoryRoom, repository: MemoryRepository = CoreDataMemoryRepository()) {
        self.room = room
        self.repository = repository
        _editingTitle = State(initialValue: room.title)
        _editingDetail = State(initialValue: room.detail ?? "")
    }

    private var attachments: [RoomAttachment] {
        guard let data = room.attachments else { return [] }
        return (try? JSONDecoder().decode([RoomAttachment].self, from: data)) ?? []
    }

    var body: some View {
        List {
            Section(header: Text("Details")) {
                if isEditing {
                    TextField("Title", text: $editingTitle)
                    TextEditor(text: $editingDetail)
                        .frame(minHeight: 100)
                } else {
                    Text(room.title)
                    if let detail = room.detail, !detail.isEmpty {
                        Text(detail)
                    }
                }
                if let date = room.date {
                    Text(date, style: .date)
                        .foregroundColor(.secondary)
                }
            }

            if !attachments.isEmpty {
                Section(header: Text("Attachments")) {
                    ForEach(attachments, id: \.id) { attachment in
                        Button(attachment.fileName) {
                            if let url = resolveBookmark(data: attachment.fileURLData) {
                                previewURL = url
                                showPreview = true
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(Text(room.title))
        .toolbar {
            Button(isEditing ? "Save" : "Edit") {
                if isEditing {
                    let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    Task {
                        do {
                            try await repository.updateRoom(room, title: trimmed, detail: editingDetail.isEmpty ? nil : editingDetail)
                        } catch let error as CitadelError {
                            alertError = error
                        } catch {
                            alertError = .unknown
                        }
                    }
                }
                isEditing.toggle()
            }
        }
        .sheet(isPresented: $showPreview) {
            if let url = previewURL {
                QuickLookPreview(url: url)
            }
        }
        .alert(item: $alertError) { error in
            Alert(title: Text(error.errorDescription ?? "Error"))
        }
    }

    private func resolveBookmark(data: Data) -> URL? {
        var stale = false
        do {
            return try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale)
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }
}

/// Wrapper for `QLPreviewController` so it can be used within SwiftUI.
struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: QLPreviewController, context: Context) {}

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) {
            self.url = url
        }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

struct MemoryRoomDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let wing = Wing(context: context)
        wing.title = "Wing"
        let room = MemoryRoom(context: context)
        room.title = "Example Room"
        room.wing = wing
        return NavigationView {
            MemoryRoomDetailView(room: room)
        }
    }
}
