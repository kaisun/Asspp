import AnyCodable
import Foundation

extension AppStoreService: AppStoreDownloadService {
    public func getDownloadInfo(account: Account, app: App) async throws -> (url: String, sinfs: [Sinf]) {
        let host = "\(Constants.privateAppStoreAPIDomainPrefixWithoutAuthCode)-\(Constants.privateAppStoreAPIDomain)"
        let url = URL(string: "https://\(host)\(Constants.privateAppStoreAPIPathDownload)?guid=\(guid)")!

        let headers = [
            "Content-Type": "application/x-apple-plist",
            "iCloud-DSID": account.directoryServicesID,
            "X-Dsid": account.directoryServicesID,
        ]

        let params: [String: Any] = [
            "creditDisplay": "",
            "guid": guid,
            "salableAdamId": app.id,
        ]

        let propertyListData = try PropertyListSerialization.data(
            fromPropertyList: params,
            format: .xml,
            options: 0
        )

        struct DownloadItem: Codable {
            let md5: String?
            let URL: String
            let sinfs: [Sinf]
            let metadata: [String: AnyCodable]
        }

        struct DownloadResponse: Decodable {
            let failureType: String?
            let customerMessage: String?
            let songList: [DownloadItem]
        }

        let (response, _) = try await HTTPClient.shared.request(
            url: url,
            method: "POST",
            headers: headers,
            body: propertyListData,
            format: .xml
        ) as (DownloadResponse, [String: String])

        if response.failureType == Constants.failureTypePasswordTokenExpired {
            throw AppStoreError.passwordTokenExpired
        }

        if response.failureType == Constants.failureTypeLicenseNotFound {
            throw AppStoreError.licenseRequired
        }

        if let failureType = response.failureType, !failureType.isEmpty {
            if let message = response.customerMessage, !message.isEmpty {
                throw AppStoreError.custom(message)
            }
            throw AppStoreError.custom("下载错误: \(failureType)")
        }

        if response.songList.isEmpty {
            throw AppStoreError.invalidResponse
        }

        let item = response.songList[0]
        return (item.URL, item.sinfs)
    }

    public func download(account: Account, app: App, outputPath: String, progressHandler: ((Double) -> Void)? = nil) async throws -> (path: String, sinfs: [Sinf]) {
        let host = "\(Constants.privateAppStoreAPIDomainPrefixWithoutAuthCode)-\(Constants.privateAppStoreAPIDomain)"
        let url = URL(string: "https://\(host)\(Constants.privateAppStoreAPIPathDownload)?guid=\(guid)")!

        let headers = [
            "Content-Type": "application/x-apple-plist",
            "iCloud-DSID": account.directoryServicesID,
            "X-Dsid": account.directoryServicesID,
        ]

        let params: [String: Any] = [
            "creditDisplay": "",
            "guid": guid,
            "salableAdamId": app.id,
        ]

        let propertyListData = try PropertyListSerialization.data(
            fromPropertyList: params,
            format: .xml,
            options: 0
        )

        struct DownloadItem: Codable {
            let md5: String?
            let URL: String
            let sinfs: [Sinf]
            let metadata: [String: AnyCodable]
        }

        struct DownloadResponse: Decodable {
            let failureType: String?
            let customerMessage: String?
            let songList: [DownloadItem]
        }

        let (response, _) = try await HTTPClient.shared.request(
            url: url,
            method: "POST",
            headers: headers,
            body: propertyListData,
            format: .xml
        ) as (DownloadResponse, [String: String])

        if response.failureType == Constants.failureTypePasswordTokenExpired {
            throw AppStoreError.passwordTokenExpired
        }

        if response.failureType == Constants.failureTypeLicenseNotFound {
            throw AppStoreError.licenseRequired
        }

        if let failureType = response.failureType, !failureType.isEmpty {
            if let message = response.customerMessage, !message.isEmpty {
                throw AppStoreError.custom(message)
            }
            throw AppStoreError.custom("下载错误: \(failureType)")
        }

        if response.songList.isEmpty {
            throw AppStoreError.invalidResponse
        }

        let item = response.songList[0]

        let destinationPath = try resolveDestinationPath(app: app, path: outputPath)
        let tmpPath = "\(destinationPath).tmp"

        try await downloadFile(from: item.URL, to: tmpPath, progressHandler: progressHandler)

        try applyPatches(item: item, account: account, sourcePath: tmpPath, destinationPath: destinationPath)

        try FileManager.default.removeItem(atPath: tmpPath)

        return (destinationPath, item.sinfs)
    }

    func downloadFile(from url: String, to path: String, progressHandler _: ((Double) -> Void)? = nil) async throws {
        guard let url = URL(string: url) else {
            throw AppStoreError.custom(String(localized: "invalid_url"))
        }

        let (downloadURL, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: downloadURL, to: URL(fileURLWithPath: path))
    }

    func resolveDestinationPath(app: App, path: String) throws -> String {
        let fileName = "\(app.bundleID)_\(app.id)_\(app.version).ipa"

        if path.isEmpty {
            let currentDir = FileManager.default.currentDirectoryPath
            return "\(currentDir)/\(fileName)"
        }

        let isDirectory = (try? FileManager.default.attributesOfItem(atPath: path)[.type] as? FileAttributeType) == .typeDirectory

        if isDirectory {
            return "\(path)/\(fileName)"
        }

        return path
    }

    func applyPatches(item: Any, account _: Account, sourcePath: String, destinationPath: String) throws {
        guard let downloadItem = item as? [String: Any],
              let sinfs = downloadItem["sinfs"] as? [Sinf]
        else {
            throw AppStoreError.custom(String(localized: "unable_to_extract_download_info"))
        }

        try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath)
        try zipUtility.replicateSinf(inputPath: destinationPath, outputPath: destinationPath, sinfs: sinfs)
    }
}
