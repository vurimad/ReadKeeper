import Testing
@testable import ReadKeeper

struct ISBNTests {
    @Test func acceptsValidISBN13WithHyphensAndSpaces() {
        #expect(ISBN.normalized("978-0-14-143951-8") == "9780141439518")
        #expect(ISBN.normalized(" 978 0141439518 ") == "9780141439518")
    }

    @Test func convertsISBN10ToISBN13() {
        // Pride and Prejudice (Penguin Classics)
        #expect(ISBN.normalized("0141439513") == "9780141439518")
        #expect(ISBN.convert10to13("0141439513") == "9780141439518")
    }

    @Test func acceptsISBN10WithXCheckDigit() {
        #expect(ISBN.isValid10("080442957X"))
        #expect(ISBN.normalized("0-8044-2957-x") == "9780804429573")
    }

    @Test func rejectsWrongChecksumsAndNonISBNText() {
        #expect(ISBN.normalized("9780141439519") == nil) // last digit wrong
        #expect(ISBN.normalized("0141439514") == nil)
        #expect(ISBN.normalized("1984") == nil) // a title, not an ISBN
        #expect(ISBN.normalized("pride and prejudice") == nil)
        #expect(ISBN.normalized("") == nil)
    }

    @Test func prefersBookISBN13FromAList() {
        let list = ["0141439513", "9780141439518", "not-an-isbn"]
        #expect(ISBN.preferred(from: list) == "9780141439518")
        #expect(ISBN.preferred(from: ["0141439513"]) == "9780141439518")
        #expect(ISBN.preferred(from: ["garbage"]) == nil)
    }
}
