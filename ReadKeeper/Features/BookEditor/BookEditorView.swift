import PhotosUI
import SwiftData
import SwiftUI

/// Form for adding a new book or editing an existing one.
struct BookEditorView: View {
    enum Mode {
        case create
        case edit(Book)
    }

    let mode: Mode
    var onSaved: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var draft: BookDraft
    @State private var photoItem: PhotosPickerItem?

    init(mode: Mode, draft: BookDraft, onSaved: (() -> Void)? = nil) {
        self.mode = mode
        self.onSaved = onSaved
        _draft = State(initialValue: draft)
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        CoverImageView(
                            data: draft.coverImageData,
                            url: draft.coverURL,
                            title: draft.title.isEmpty ? "New Book" : draft.title,
                            author: draft.author
                        )
                        .frame(width: 80, height: 120)

                        VStack(alignment: .leading, spacing: 10) {
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                Label(draft.hasCover ? "Change cover" : "Add a cover", systemImage: "photo")
                            }
                            if draft.hasCover {
                                Button("Remove cover", role: .destructive) {
                                    draft.coverImageData = nil
                                    draft.coverURL = nil
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Book") {
                    TextField("Title", text: $draft.title)
                        .textInputAutocapitalization(.words)
                    TextField("Author", text: $draft.author)
                        .textInputAutocapitalization(.words)
                    TextField("Pages", text: $draft.pageCountText)
                        .keyboardType(.numberPad)
                    TextField("Year published", text: $draft.yearText)
                        .keyboardType(.numberPad)
                    TextField("Publisher", text: $draft.publisher)
                }

                Section("Edition") {
                    Picker("Format", selection: $draft.format) {
                        ForEach(BookFormat.allCases) { format in
                            Label(format.title, systemImage: format.systemImage).tag(format)
                        }
                    }
                    if let isbn = draft.isbn13 {
                        LabeledContent("ISBN", value: isbn)
                    }
                }

                Section {
                    Picker("Status", selection: $draft.status) {
                        ForEach(ReadingStatus.allCases) { status in
                            Label(status.title, systemImage: status.systemImage).tag(status)
                        }
                    }
                } header: {
                    Text("Status")
                } footer: {
                    if let message = draft.validationMessage {
                        Text(message).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Book" : "Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(!draft.isValid)
                }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        draft.coverImageData = ImageDownscaler.jpegData(from: data) ?? data
                    }
                }
            }
        }
    }

    private func save() {
        switch mode {
        case .create:
            let book = draft.makeBook()
            modelContext.insert(book)
            try? modelContext.save()
            if book.coverImageData == nil, let url = draft.coverURL {
                // Keep a copy of the online cover so it shows offline too.
                let context = modelContext
                Task {
                    if let data = await CoverFetcher.fetch(url) {
                        book.coverImageData = data
                        try? context.save()
                    }
                }
            }
        case .edit(let book):
            draft.apply(to: book)
            try? modelContext.save()
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
        onSaved?()
    }
}

#Preview {
    BookEditorView(mode: .create, draft: BookDraft())
        .modelContainer(Persistence.previewContainer(withDemoBooks: false))
}
