import Foundation

/// Fetches data from the network. A protocol so tests can supply canned responses.
protocol HTTPClient: Sendable {
    func get(_ url: URL) async throws -> Data
}

enum HTTPClientError: Error, Equatable {
    case badStatus(Int)
}

struct URLSessionHTTPClient: HTTPClient {
    /// Generic app identifier only; no personal details are ever sent.
    static let userAgent = "ReadKeeper/0.1 (iOS)"

    func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw HTTPClientError.badStatus(http.statusCode)
        }
        return data
    }
}
