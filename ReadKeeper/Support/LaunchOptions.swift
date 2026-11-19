import Foundation

/// Launch arguments used by CI to open specific screens for screenshots.
///
/// Examples: `-RKStartTab library`, `-RKDemoShelf YES`, `-RKOpenAdd YES -RKSearchQuery "pride and prejudice"`
enum LaunchOptions {
    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static var initialTab: AppTab {
        value(after: "-RKStartTab").flatMap(AppTab.init(rawValue:)) ?? .shelf
    }

    /// Fills the library with demo books (in memory). Debug builds only.
    static var showsDemoShelf: Bool {
        debugOnly(arguments.contains("-RKDemoShelf"))
    }

    /// Uses a throwaway in-memory database (demo data, screenshots, tests).
    static var usesInMemoryStore: Bool {
        showsDemoShelf || debugOnly(arguments.contains("-RKInMemory"))
    }

    /// Opens the Add Book sheet on launch.
    static var opensAddSheet: Bool {
        debugOnly(arguments.contains("-RKOpenAdd"))
    }

    /// Pre-fills the Add Book search field.
    static var initialSearchQuery: String? {
        debugOnly(value(after: "-RKSearchQuery"))
    }

    /// Opens the book with this title from the shelf on launch.
    static var openBookTitle: String? {
        debugOnly(value(after: "-RKOpenBook"))
    }

    /// Opens the Log Progress sheet on the book opened with `-RKOpenBook`.
    static var opensLogSheet: Bool {
        debugOnly(arguments.contains("-RKOpenLog"))
    }

    /// Opens Settings → Import & Export on launch.
    static var opensImportExport: Bool {
        debugOnly(arguments.contains("-RKOpenImportExport"))
    }

    /// Shows the import review for a built-in sample Goodreads export.
    static var showsSampleImport: Bool {
        debugOnly(arguments.contains("-RKSampleImport"))
    }

    /// Shows every widget design at real size (debug gallery for screenshots).
    static var showsWidgetGallery: Bool {
        debugOnly(arguments.contains("-RKWidgetGallery"))
    }

    /// Opens a share card on launch: "shelf", "book" or "year".
    static var shareCard: String? {
        debugOnly(value(after: "-RKShareCard"))
    }

    /// Scrolls the Stats tab to a section on launch (e.g. "year").
    static var statsScrollTarget: String? {
        debugOnly(value(after: "-RKStatsScrollTo"))
    }

    /// Freezes the shelf tilt at this value (-1...1) for screenshots, since the Simulator has no motion sensor.
    static var fixedTilt: Double? {
        debugOnly(value(after: "-RKTilt")).flatMap(Double.init)
    }

    private static func value(after flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }

    private static func debugOnly(_ value: Bool) -> Bool {
        #if DEBUG
        return value
        #else
        return false
        #endif
    }

    private static func debugOnly(_ value: String?) -> String? {
        #if DEBUG
        return value
        #else
        return nil
        #endif
    }
}
