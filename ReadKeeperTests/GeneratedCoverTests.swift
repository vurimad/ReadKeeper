import Testing
@testable import ReadKeeper

struct GeneratedCoverTests {
    @Test func longestWordAlwaysFitsTheWidth() {
        for title in ["Pride and Prejudice", "Frankenstein", "Alice's Adventures in Wonderland", "Moby-Dick"] {
            let width = 35.0
            let size = GeneratedCover.fontSize(for: title, width: width)
            let longest = title.split(whereSeparator: { $0 == " " || $0 == "-" }).map(\.count).max() ?? 1
            let estimatedWordWidth = Double(longest) * 0.6 * size
            #expect(estimatedWordWidth <= width + 0.001 || size == 5, "\(title) at \(size)pt")
        }
    }

    @Test func fontSizeStaysInRange() {
        #expect(GeneratedCover.fontSize(for: "It", width: 500) == 20)
        #expect(GeneratedCover.fontSize(for: "Supercalifragilisticexpialidocious", width: 20) == 5)
    }
}
