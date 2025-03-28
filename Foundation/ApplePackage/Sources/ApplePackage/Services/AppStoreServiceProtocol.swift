import Foundation

public protocol AppStoreAuthenticationService {
    func login(email: String, password: String, authCode: String) async throws -> Account
}

public protocol AppStoreSearchService {
    func search(account: Account, term: String, limit: Int) async throws -> [App]
    func lookup(account: Account, bundleID: String) async throws -> App
}

public protocol AppStorePurchaseService {
    func purchase(account: Account, app: App) async throws
}

public protocol AppStoreDownloadService {
    func download(account: Account, app: App, outputPath: String, progressHandler: ((Double) -> Void)?) async throws -> (path: String, sinfs: [Sinf])
    func getDownloadInfo(account: Account, app: App) async throws -> (url: String, sinfs: [Sinf])
}
