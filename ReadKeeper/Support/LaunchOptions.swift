import Foundation

/// Launch arguments used by CI to open specific screens for screenshots.
///
/// Example: `-RKStartTab library` or `-RKDemoShelf YES`
enum LaunchOptions {
    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static var initialTab: AppTab {
        value(after: "-RKStartTab").flatMap(AppTab.init(rawValue:)) ?? .shelf
    }

    /// Fills the shelf with demo books. Debug builds only.
    static var showsDemoShelf: Bool {
        #if DEBUG
        return arguments.contains("-RKDemoShelf")
        #else
        return false
        #endif
    }

    private static func value(after flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }
}
