import Foundation
import UIKit

/// Downloads a cover so the book still has it offline.
enum CoverFetcher {
    static func fetch(_ url: URL, client: any HTTPClient = URLSessionHTTPClient()) async -> Data? {
        guard let data = try? await client.get(url) else { return nil }
        // Open Library returns a tiny placeholder image when there's no cover; skip those.
        guard data.count > 1_000, data.count < 5_000_000, UIImage(data: data) != nil else { return nil }
        return data
    }
}

/// Shrinks photos picked by the user so the library stays small.
@MainActor
enum ImageDownscaler {
    static func jpegData(from data: Data, maxDimension: CGFloat = 900, quality: CGFloat = 0.82) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        guard longest > 0 else { return nil }
        let scale = min(1, maxDimension / longest)
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
