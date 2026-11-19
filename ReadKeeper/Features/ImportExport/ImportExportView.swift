import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Settings → Import & Export.
struct ImportExportView: View {
    @Query private var books: [Book]
    @Environment(\.modelContext) private var modelContext

    private enum PickerMode {
        case importCSV
        case restoreBackup

        var contentTypes: [UTType] {
            switch self {
            case .importCSV: [.commaSeparatedText, .plainText, .text]
            case .restoreBackup: [.json]
            }
        }
    }

    @State private var pickerMode: PickerMode?
    @State private var plan: ImportPlan?
    @State private var exportFile: ExportFile?
    @State private var exportName = ""
    @State private var exportType: UTType = .commaSeparatedText
    @State private var message: AlertMessage?

    var body: some View {
        Form {
            Section {
                Button {
                    pickerMode = .importCSV
                } label: {
                    Label("Import from Goodreads or StoryGraph", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("Bring your library")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("**Goodreads:** on the website, go to My Books → Import and export → Export Library, then download the file.")
                    Text("**StoryGraph:** on the website, go to Manage Account → Export StoryGraph Library.")
                    Text("Then choose the .csv file here. Nothing is added until you review it. Importing is always free.")
                }
            }

            Section {
                Button {
                    exportCSV()
                } label: {
                    Label("Export as Spreadsheet (CSV)", systemImage: "tablecells")
                }
                .disabled(books.isEmpty)

                Button {
                    exportBackup()
                } label: {
                    Label("Export Full Backup", systemImage: "externaldrive")
                }
                .disabled(books.isEmpty)

                Button {
                    pickerMode = .restoreBackup
                } label: {
                    Label("Restore from Backup", systemImage: "arrow.counterclockwise")
                }
            } header: {
                Text("Your data")
            } footer: {
                Text("Your books are yours. The spreadsheet opens in Excel, Numbers or Google Sheets. The full backup also keeps your reading history and quotes.")
            }
        }
        .navigationTitle("Import & Export")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: Binding(get: { pickerMode != nil }, set: { if !$0 { pickerMode = nil } }),
            allowedContentTypes: pickerMode?.contentTypes ?? [.commaSeparatedText]
        ) { result in
            let mode = pickerMode
            pickerMode = nil
            handlePicked(result, mode: mode)
        }
        .fileExporter(
            isPresented: Binding(get: { exportFile != nil }, set: { if !$0 { exportFile = nil } }),
            document: exportFile,
            contentType: exportType,
            defaultFilename: exportName
        ) { result in
            if case .failure(let error) = result {
                message = AlertMessage(title: "Couldn't save the file", text: error.localizedDescription)
            }
        }
        .sheet(item: $plan) { plan in
            ImportReviewView(plan: plan)
        }
        .alert(item: $message) { message in
            Alert(title: Text(message.title), message: Text(message.text))
        }
        .task {
            #if DEBUG
            if LaunchOptions.showsSampleImport, plan == nil {
                plan = try? LibraryImporter.plan(
                    text: DemoLibrary.sampleGoodreadsCSV,
                    existingKeys: LibraryImporter.existingKeys(for: books)
                )
            }
            #endif
        }
    }

    // MARK: Actions

    private func handlePicked(_ result: Result<URL, Error>, mode: PickerMode?) {
        do {
            let url = try result.get()
            let data = try Self.readFile(at: url)
            switch mode {
            case .restoreBackup:
                let backup = try LibraryBackup.decode(data)
                let restored = backup.restore(into: modelContext, existingIDs: Set(books.map(\.id)))
                message = AlertMessage(
                    title: "Backup restored",
                    text: restored == 0
                        ? "Every book in this backup is already in your library."
                        : "Restored \(restored) \(restored == 1 ? "book" : "books")."
                )
            case .importCSV, .none:
                let text = String(decoding: data, as: UTF8.self)
                plan = try LibraryImporter.plan(text: text, existingKeys: LibraryImporter.existingKeys(for: books))
            }
        } catch let error as ImportError {
            message = AlertMessage(title: "Can't import this file", text: error.localizedDescription)
        } catch is DecodingError {
            message = AlertMessage(title: "Can't restore this file", text: "This isn't a ReadKeeper backup file.")
        } catch {
            message = AlertMessage(title: "Couldn't open the file", text: error.localizedDescription)
        }
    }

    private static func readFile(at url: URL) throws -> Data {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        return try Data(contentsOf: url)
    }

    private func exportCSV() {
        exportType = .commaSeparatedText
        exportName = "ReadKeeper Library \(LibraryCSVExport.day(.now).replacingOccurrences(of: "/", with: "-"))"
        exportFile = ExportFile(data: Data(LibraryCSVExport.csv(for: books).utf8))
    }

    private func exportBackup() {
        do {
            exportType = .json
            exportName = "ReadKeeper Backup \(LibraryCSVExport.day(.now).replacingOccurrences(of: "/", with: "-"))"
            exportFile = ExportFile(data: try LibraryBackup(books: books).encoded())
        } catch {
            message = AlertMessage(title: "Couldn't create the backup", text: error.localizedDescription)
        }
    }
}

struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let text: String
}

#Preview {
    NavigationStack {
        ImportExportView()
    }
    .modelContainer(Persistence.previewContainer())
}
