import Foundation

/// Helpers for tropes and tags: trimmed, no duplicates (ignoring case), original order kept.
enum TagList {
    static func adding(_ raw: String, to list: [String]) -> [String] {
        guard let value = raw.nilIfBlank else { return list }
        let exists = list.contains { $0.caseInsensitiveCompare(value) == .orderedSame }
        return exists ? list : list + [value]
    }

    static func removing(_ value: String, from list: [String]) -> [String] {
        list.filter { $0.caseInsensitiveCompare(value) != .orderedSame }
    }

    /// Popular tropes readers search for (BookTok favorites first).
    static let tropeSuggestions = [
        "Enemies to lovers", "Slow burn", "Found family", "Forced proximity", "Fake dating",
        "Grumpy × sunshine", "Second chance", "Friends to lovers", "Morally grey", "Chosen one",
        "Dark academia", "Cozy", "Magic school", "Heist", "Unreliable narrator", "Twist ending",
    ]
}
