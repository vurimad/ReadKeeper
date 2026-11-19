import Foundation
import SwiftData

@MainActor
enum Persistence {
    static let schema = Schema([Book.self, ReadingLog.self, Quote.self])

    /// The app's database. Stored on the device for now; iCloud sync is switched on in milestone M4.
    static func makeContainer() -> ModelContainer {
        // The database lives in Application Support, which doesn't exist on a fresh install.
        // Creating it first avoids noisy CoreData errors on first launch.
        try? FileManager.default.createDirectory(at: URL.applicationSupportDirectory, withIntermediateDirectories: true)

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: LaunchOptions.usesInMemoryStore,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            if LaunchOptions.showsDemoShelf {
                DemoLibrary.seed(into: container.mainContext)
                // Registered defaults aren't saved to disk, so the demo goal never leaks into real use.
                UserDefaults.standard.register(defaults: [ReadingGoal.storageKey: DemoLibrary.yearlyGoal])
            }
            return container
        } catch {
            fatalError("Could not open the library database: \(error)")
        }
    }

    /// In-memory container for previews.
    static func previewContainer(withDemoBooks: Bool = true) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            if withDemoBooks {
                DemoLibrary.seed(into: container.mainContext)
            }
            return container
        } catch {
            fatalError("Could not create preview database: \(error)")
        }
    }
}
