import SwiftUI

enum AppTab: String, Hashable, CaseIterable {
    case shelf
    case library
    case stats
    case settings
}

struct RootView: View {
    @State private var selection: AppTab = LaunchOptions.initialTab

    var body: some View {
        TabView(selection: $selection) {
            Tab("Shelf", systemImage: "books.vertical", value: AppTab.shelf) {
                ShelfView()
            }
            Tab("Library", systemImage: "list.bullet", value: AppTab.library) {
                LibraryView()
            }
            Tab("Stats", systemImage: "chart.bar", value: AppTab.stats) {
                StatsView()
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                SettingsView()
            }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    RootView()
}
