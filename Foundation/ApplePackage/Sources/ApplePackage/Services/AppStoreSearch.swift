import Foundation

extension AppStoreService: AppStoreSearchService {
    public func search(account: Account, term: String, limit: Int = 10) async throws -> [App] {
        let countryCode = try storefrontService.countryCodeFromStoreFront(storeFront: account.storeFront)

        var components = URLComponents(string: "https://\(Constants.iTunesAPIDomain)\(Constants.iTunesAPIPathSearch)")!
        components.queryItems = [
            URLQueryItem(name: "entity", value: "software,iPadSoftware"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "media", value: "software"),
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "country", value: countryCode),
        ]

        guard let url = components.url else {
            throw AppStoreError.custom(String(localized: "unable_to_build_search_url"))
        }

        struct SearchResponse: Decodable {
            let resultCount: Int
            let results: [App]
        }

        let (response, _) = try await HTTPClient.shared.request(
            url: url,
            method: "GET",
            format: .json
        ) as (SearchResponse, [String: String])

        return response.results
    }

    public func lookup(account: Account, bundleID: String) async throws -> App {
        let countryCode = try storefrontService.countryCodeFromStoreFront(storeFront: account.storeFront)

        var components = URLComponents(string: "https://\(Constants.iTunesAPIDomain)\(Constants.iTunesAPIPathLookup)")!
        components.queryItems = [
            URLQueryItem(name: "entity", value: "software,iPadSoftware"),
            URLQueryItem(name: "limit", value: "1"),
            URLQueryItem(name: "media", value: "software"),
            URLQueryItem(name: "bundleId", value: bundleID),
            URLQueryItem(name: "country", value: countryCode),
        ]

        guard let url = components.url else {
            throw AppStoreError.custom(String(localized: "unable_to_build_lookup_url"))
        }

        struct LookupResponse: Decodable {
            let resultCount: Int
            let results: [App]
        }

        let (response, _) = try await HTTPClient.shared.request(
            url: url,
            method: "GET",
            format: .json
        ) as (LookupResponse, [String: String])

        if response.results.isEmpty {
            throw AppStoreError.appNotFound
        }

        return response.results[0]
    }
}
