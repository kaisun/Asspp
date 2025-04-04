import Foundation

public class HTTPClient: NSObject, URLSessionTaskDelegate {
    private var session: URLSession!

    override init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        super.init()
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
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
        responseFormat: ResponseFormat = .json
    ) async throws -> (T, [String: String]) {
        var request = URLRequest(url: url)
        request.httpMethod = method

        if !headers.keys.contains("User-Agent") {
            request.addValue(Constants.defaultUserAgent, forHTTPHeaderField: "User-Agent")
        }

        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }

        if let body { request.httpBody = body }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppStoreError.invalidResponse
        }

        let headers = httpResponse.allHeaderFields.reduce(into: [String: String]()) { result, item in
            if let key = item.key as? String, let value = item.value as? String {
                result[key.lowercased()] = value
            }
        }

        switch responseFormat {
        case .json:
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(T.self, from: data)
            return (decoded, headers)
        case .xml:
            let decoder = PropertyListDecoder()
            let decoded = try decoder.decode(T.self, from: data)
            return (decoded, headers)
        }
    }

    // prevent redirect
    public func urlSession(
        _: URLSession,
        task _: URLSessionTask,
        willPerformHTTPRedirection _: HTTPURLResponse,
        newRequest: URLRequest
    ) async -> URLRequest? {
        return nil
    }

    public func urlSession(
        _: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        #if DEBUG
            if let trust = challenge.protectionSpace.serverTrust {
                print("[*] allowing insecure networking @ DEBUG")
                completionHandler(.useCredential, .init(trust: trust))
                return
            }
        #endif
        completionHandler(.performDefaultHandling, nil)
    }
}
