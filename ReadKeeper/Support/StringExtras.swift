import Foundation

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The trimmed string, or nil when it's empty.
    var nilIfBlank: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }
}
