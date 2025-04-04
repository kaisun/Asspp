import Foundation

extension AppStoreService: AppStoreSearchService {
    public nonisolated
    func search(
        countryCode: String,
        entityType: EntityType = .iPhone,
        term: String,
        limit: Int = 10
    ) async throws -> [AppPackage] {
        var components = URLComponents(string: "https://\(Constants.iTunesAPIDomain)\(Constants.iTunesAPIPathSearch)")!
        components.queryItems = [
            URLQueryItem(name: "entity", value: entityType.searchParameterValue),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "media", value: "software"),
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "country", value: countryCode),
        ]

        guard let url = components.url else {
            throw AppStoreError.custom(String(localized: "unable_to_build_search_url", bundle: .module))
        }

        struct SearchResponse: Decodable {
            let resultCount: Int
            let results: [AppPackage]
        }

        let (response, _) = try await HTTPClient().request(
            url: url,
            method: "GET",
            responseFormat: .json
        ) as (SearchResponse, [String: String])

        return response.results
    }

    public nonisolated
    func lookup(account: Account, bundleID: String) async throws -> AppPackage {
        let countryCode = try storefront.countryCodeLookup(storeFront: account.storeFront)

        var components = URLComponents(string: "https://\(Constants.iTunesAPIDomain)\(Constants.iTunesAPIPathLookup)")!
        components.queryItems = [
            URLQueryItem(name: "entity", value: "software,iPadSoftware"),
            URLQueryItem(name: "limit", value: "1"),
            URLQueryItem(name: "media", value: "software"),
            URLQueryItem(name: "bundleId", value: bundleID),
            URLQueryItem(name: "country", value: countryCode),
        ]

        guard let url = components.url else {
            throw AppStoreError.custom(String(localized: "unable_to_build_lookup_url", bundle: .module))
        }

        struct LookupResponse: Decodable {
            let resultCount: Int
            let results: [AppPackage]
        }

        let (response, _) = try await HTTPClient().request(
            url: url,
            method: "GET",
            responseFormat: .json
        ) as (LookupResponse, [String: String])

        if response.results.isEmpty {
            throw AppStoreError.appNotFound
        }

        return response.results[0]
    }
}
