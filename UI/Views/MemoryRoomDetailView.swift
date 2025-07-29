import SwiftUI
import QuickLook

/// Displays details for a single memory room including its attachments.
struct MemoryRoomDetailView: View {
    let room: MemoryRoom
    @State private var previewURL: URL?
    @State private var showPreview = false

    private var attachments: [RoomAttachment] {
        guard let data = room.attachments else { return [] }
        return (try? JSONDecoder().decode([RoomAttachment].self, from: data)) ?? []
    }

    var body: some View {
        List {
            Section(header: Text("Details")) {
                if let detail = room.detail, !detail.isEmpty {
                    Text(detail)
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
        .sheet(isPresented: $showPreview) {
            if let url = previewURL {
                QuickLookPreview(url: url)
            }
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
