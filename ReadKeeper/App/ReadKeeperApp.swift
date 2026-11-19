import SwiftData
import SwiftUI

@main
struct ReadKeeperApp: App {
    private let container: ModelContainer

    init() {
        container = Persistence.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
