import Foundation

public protocol AppStoreAuthenticationService {
    nonisolated
    func login(
        email: String,
        password: String,
        authCode: String
    ) async throws -> Account
}

public protocol AppStoreSearchService {
    nonisolated
    func search(
        countryCode: String,
        entityType: EntityType,
        term: String,
        limit: Int
    ) async throws -> [AppPackage]

    nonisolated
    func lookup(
        account: Account,
        bundleID: String
    ) async throws -> AppPackage
}

public protocol AppStorePurchaseService {
    func purchase(account: Account, app: AppPackage) async throws
}

public protocol AppStoreDownloadService {
    nonisolated
    func download(
        account: Account,
        app: AppPackage,
        outputPath: String,
        progressHandler: ((Double) -> Void)?
    ) async throws

    nonisolated
    func getDownloadInfo(
        account: Account,
        app: AppPackage
    ) async throws -> (
        url: String,
        sinfs: [Sinf],
        md5: String
    )
}
