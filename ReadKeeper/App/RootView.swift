import SwiftData
import SwiftUI

enum AppTab: String, Hashable, CaseIterable {
    case shelf
    case library
    case stats
    case settings
}

struct RootView: View {
    @State private var selection: AppTab = LaunchOptions.initialTab
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    #if DEBUG
    @Query private var books: [Book]
    @State private var showingWidgetGallery = LaunchOptions.showsWidgetGallery
    @State private var debugShareCard: ShareCardKind?
    #endif

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
        .onChange(of: scenePhase) { _, phase in
            // Keep widgets current whenever the user leaves the app.
            if phase != .active {
                WidgetRefresher.refresh(context: modelContext)
            }
        }
        #if DEBUG
        .fullScreenCover(isPresented: $showingWidgetGallery) {
            WidgetGalleryView()
        }
        .sheet(item: $debugShareCard) { kind in
            ShareCardSheet(kind: kind)
        }
        .task {
            switch LaunchOptions.shareCard {
            case "shelf": debugShareCard = .shelf
            case "year": debugShareCard = .year
            case "book":
                if let book = books.first(where: { $0.title == "Jane Eyre" }) ?? books.first {
                    debugShareCard = .book(book)
                }
            default: break
            }
        }
        #endif
    }
}

#Preview {
    RootView()
        .modelContainer(Persistence.previewContainer())
}
