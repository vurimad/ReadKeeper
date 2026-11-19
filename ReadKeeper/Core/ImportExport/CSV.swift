import Foundation

/// A parsed CSV file with a header row.
struct CSVTable: Sendable {
    let headers: [String]
    let rows: [[String]]
    private let indexByHeader: [String: Int]

    init(headers: [String], rows: [[String]]) {
        self.headers = headers
        self.rows = rows
        var index: [String: Int] = [:]
        for (position, header) in headers.enumerated() where index[header] == nil {
            index[header] = position
        }
        indexByHeader = index
    }

    func hasColumns(_ names: [String]) -> Bool {
        names.allSatisfy { indexByHeader[$0] != nil }
    }

    /// The cell for `column` in `row`, or nil when the column is missing or the cell is blank.
    func value(_ column: String, in row: [String]) -> String? {
        guard let index = indexByHeader[column], index < row.count else { return nil }
        return row[index].nilIfBlank
    }
}

/// Reads CSV the way spreadsheets write it (RFC 4180): quoted fields, doubled quotes,
/// commas and line breaks inside quotes, LF or CRLF line endings, optional byte-order mark.
enum CSVParser {
    static func parseRows(_ text: String) -> [[String]] {
        var input = text
        if input.hasPrefix("\u{FEFF}") { input.removeFirst() }

        let characters = Array(input)
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var index = 0

        while index < characters.count {
            let character = characters[index]
            if inQuotes {
                if character == "\"" {
                    if index + 1 < characters.count && characters[index + 1] == "\"" {
                        field.append("\"")
                        index += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(character)
                }
            } else {
                switch character {
                case "\"" where field.isEmpty:
                    inQuotes = true
                case ",":
                    row.append(field)
                    field = ""
                case "\n", "\r\n", "\r":
                    row.append(field)
                    rows.append(row)
                    row = []
                    field = ""
                default:
                    field.append(character)
                }
            }
            index += 1
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        // Drop completely empty lines.
        return rows.filter { !($0.count == 1 && $0[0].trimmed.isEmpty) }
    }

    static func parseTable(_ text: String) -> CSVTable? {
        let rows = parseRows(text)
        guard let header = rows.first else { return nil }
        return CSVTable(headers: header.map(\.trimmed), rows: Array(rows.dropFirst()))
    }
}

/// Writes CSV that opens cleanly in Excel, Numbers and Google Sheets.
enum CSVWriter {
    static func escape(_ field: String) -> String {
        let needsQuotes = field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" || $0 == "\r\n" })
        guard needsQuotes else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    static func document(header: [String], rows: [[String]]) -> String {
        let lines = ([header] + rows).map { $0.map(escape).joined(separator: ",") }
        // The byte-order mark makes Excel read accented characters correctly.
        return "\u{FEFF}" + lines.joined(separator: "\n") + "\n"
    }
}

/// Dates in Goodreads / StoryGraph exports look like "2024/03/15" (sometimes "2024-03-15").
enum ImportDate {
    /// Noon on that day, so time zones never shift it to the previous or next day.
    static func parse(_ raw: String?, calendar: Calendar = .current) -> Date? {
        guard let token = raw?.trimmed.split(separator: " ").first else { return nil }
        let parts = token.split(whereSeparator: { $0 == "/" || $0 == "-" }).compactMap { Int($0) }
        guard parts.count == 3, (1000...9999).contains(parts[0]),
              (1...12).contains(parts[1]), (1...31).contains(parts[2]) else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }
}
