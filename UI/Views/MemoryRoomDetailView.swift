import SwiftUI
import QuickLook

/// Displays detailed information for a single memory room including
/// its attachments. Selecting an attachment presents a Quick Look
/// preview of the file.
struct MemoryRoomDetailView: View {
    let room: MemoryRoom
    @State private var previewURL: URL?
    @State private var showPreview = false

    private var attachments: [RoomAttachment] {
        guard let data = room.attachments,
              let decoded = try? JSONDecoder().decode([RoomAttachment].self, from: data) else {
            return []
        }
        return decoded
    }

    var body: some View {
        List {
            Section(header: Text("Details")) {
                Text(room.title)
                    .font(.headline)
                if let detail = room.detail, !detail.isEmpty {
                    Text(detail)
                }
                if let date = room.date {
                    Text(date, style: .date)
                }
            }
            if !attachments.isEmpty {
                Section(header: Text("Attachments")) {
                    ForEach(attachments) { attachment in
                        Button(attachment.fileName) {
                            openAttachment(attachment)
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

    private func openAttachment(_ attachment: RoomAttachment) {
        do {
            var stale = false
            let url = try URL(resolvingBookmarkData: attachment.fileURLData,
                              options: [.withoutUI],
                              relativeTo: nil,
                              bookmarkDataIsStale: &stale)
            previewURL = url
            showPreview = true
        } catch {
            print("Failed to resolve URL from bookmark: \(error)")
        }
    }
}

/// Wrapper for `QLPreviewController` so it can be presented from SwiftUI.
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

        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

