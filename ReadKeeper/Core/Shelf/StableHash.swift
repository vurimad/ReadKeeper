import Foundation

/// Deterministic hash (FNV-1a, 64-bit). Swift's `hashValue` changes between launches,
/// so we use this to make a book's generated spine look the same forever.
enum StableHash {
    static func fnv1a(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }
}
