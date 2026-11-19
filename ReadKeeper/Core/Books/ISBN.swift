import Foundation

/// ISBN validation and conversion. Everything is stored as ISBN-13.
enum ISBN {
    /// Returns a valid ISBN-13 if `raw` is an ISBN-10 or ISBN-13 (hyphens and spaces allowed), otherwise nil.
    static func normalized(_ raw: String) -> String? {
        let allowed = Set("0123456789Xx- ")
        let value = raw.trimmed
        guard !value.isEmpty, value.allSatisfy({ allowed.contains($0) }) else { return nil }

        let compact = value.uppercased().filter { $0.isNumber || $0 == "X" }
        switch compact.count {
        case 13 where isValid13(compact):
            return compact
        case 10 where isValid10(compact):
            return convert10to13(compact)
        default:
            return nil
        }
    }

    /// Picks the best ISBN from a list: a valid 978/979 ISBN-13 first, otherwise a converted ISBN-10.
    static func preferred(from candidates: [String]) -> String? {
        let normalizedValues = candidates.compactMap(normalized)
        return normalizedValues.first { $0.hasPrefix("978") || $0.hasPrefix("979") } ?? normalizedValues.first
    }

    static func isValid13(_ value: String) -> Bool {
        let digits = value.compactMap(\.wholeNumberValue)
        guard digits.count == 13, value.count == 13 else { return false }
        let sum = digits.enumerated().reduce(0) { total, item in
            total + item.element * (item.offset.isMultiple(of: 2) ? 1 : 3)
        }
        return sum.isMultiple(of: 10)
    }

    static func isValid10(_ value: String) -> Bool {
        let characters = Array(value)
        guard characters.count == 10 else { return false }
        var sum = 0
        for (index, character) in characters.enumerated() {
            let digit: Int
            if index == 9, character == "X" {
                digit = 10
            } else if let number = character.wholeNumberValue {
                digit = number
            } else {
                return false
            }
            sum += digit * (10 - index)
        }
        return sum.isMultiple(of: 11)
    }

    static func convert10to13(_ isbn10: String) -> String {
        let core = "978" + isbn10.prefix(9)
        let digits = core.compactMap(\.wholeNumberValue)
        let sum = digits.enumerated().reduce(0) { total, item in
            total + item.element * (item.offset.isMultiple(of: 2) ? 1 : 3)
        }
        let check = (10 - sum % 10) % 10
        return core + String(check)
    }
}
