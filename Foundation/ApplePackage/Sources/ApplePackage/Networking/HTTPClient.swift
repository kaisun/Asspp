import Foundation
import XMLCoder

public class HTTPClient {
    private let session: URLSession
    public static let shared = HTTPClient()

    private init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        session = URLSession(configuration: config)
    }

    public enum ResponseFormat {
        case json
        case xml
    }

    public func request<T: Decodable>(
        url: URL,
        method: String,
        headers: [String: String] = [:],
        body: Data? = nil,
        format: ResponseFormat = .json
    ) async throws -> (T, [String: String]) {
        var request = URLRequest(url: url)
        request.httpMethod = method

        if !headers.keys.contains("User-Agent") {
            request.addValue(Constants.defaultUserAgent, forHTTPHeaderField: "User-Agent")
        }

        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }

        if let body {
            request.httpBody = body
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppStoreError.invalidResponse
        }

        let headers = httpResponse.allHeaderFields.reduce(into: [String: String]()) { result, item in
            if let key = item.key as? String, let value = item.value as? String {
                result[key] = value
            }
        }

        switch format {
        case .json:
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(T.self, from: data)
            return (decoded, headers)
        case .xml:
            let decoder = XMLDecoder()
            let decoded = try decoder.decode(T.self, from: data)
            return (decoded, headers)
        }
    }
}
