#if DEBUG
import Foundation

extension DemoLibrary {
    /// A small export in Goodreads' exact format (public-domain classics) for previews, tests and screenshots.
    /// Includes the tricky parts of real exports: ="..." ISBNs, quoted commas, doubled quotes,
    /// HTML line breaks in reviews, a custom DNF shelf, and a book without an ISBN.
    static let sampleGoodreadsCSV = #"""
    Book Id,Title,Author,Author l-f,Additional Authors,ISBN,ISBN13,My Rating,Average Rating,Publisher,Binding,Number of Pages,Year Published,Original Publication Year,Date Read,Date Added,Bookshelves,Bookshelves with positions,Exclusive Shelf,My Review,Spoiler,Private Notes,Read Count,Owned Copies
    1885,Pride and Prejudice,Jane Austen,"Austen, Jane",,"=""0141439513""","=""9780141439518""",5,4.29,Penguin Classics,Paperback,480,2002,1813,2025/02/14,2025/01/03,"classics, favorites","classics (#1), favorites (#3)",read,"Witty, warm and sharp.<br/><br/>Lizzie is ""the best"".",,,2,1
    10210,Jane Eyre,Charlotte Brontë,"Brontë, Charlotte",,"=""""","=""9780141441146""",4,4.15,Penguin Classics,Paperback,532,2006,1847,2025/04/02,2025/03/10,classics,classics (#2),read,,,,1,0
    18490,Frankenstein,Mary Shelley,"Shelley, Mary",,"=""""","=""9780141439471""",4,3.89,Penguin Classics,Paperback,273,2003,1818,2025/10/31,2025/10/01,"classics, spooky-season",,read,,,,1,0
    17245,Dracula,Bram Stoker,"Stoker, Bram",,"=""""","=""9780141439846""",0,4.02,Penguin Classics,Kindle Edition,488,2003,1897,,2026/10/20,spooky-season,,currently-reading,,,,0,0
    153747,Moby-Dick,Herman Melville,"Melville, Herman",,"=""""","=""9780142437247""",0,3.53,Penguin Classics,Audible Audio,720,2003,1851,,2026/06/01,did-not-finish,,did-not-finish,,,,0,0
    6185,Wuthering Heights,Emily Brontë,"Brontë, Emily",,"=""""","=""9780141439556""",0,3.88,Penguin Classics,Hardcover,416,2003,1847,,2026/09/12,,,to-read,,,,0,0
    2956,The Adventures of Huckleberry Finn,Mark Twain,"Twain, Mark",,"=""""","=""""",0,3.82,Some Old Press,Paperback,366,1994,1884,,2026/11/02,,,to-read,,,,0,0
    """#
}
#endif
