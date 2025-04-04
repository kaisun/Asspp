import AnyCodable
import Foundation

extension AppStoreService: AppStoreDownloadService {
    private struct DownloadItem: Codable {
        let md5: String?
        let URL: String
        let sinfs: [Sinf]
        let metadata: [String: AnyCodable]
    }

    private struct DownloadResponse: Decodable {
        let failureType: String?
        let customerMessage: String?
        let songList: [DownloadItem]
    }

    private nonisolated func fetchDownloadInfo(
        account: Account,
        appID: Int64
    ) async throws -> DownloadItem {
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
            "salableAdamId": appID,
        ]

        let propertyListData = try PropertyListSerialization.data(
            fromPropertyList: params,
            format: .xml,
            options: 0
        )

        var currentLocation: URL = url
        var response: DownloadResponse?
        
        while true {
            let (thisResponse, thisResponseHeader) = try await HTTPClient().request(
                url: currentLocation,
                method: "POST",
                headers: headers,
                body: propertyListData,
                responseFormat: .xml
            ) as (DownloadResponse, [String: String])
            if let newLocation = thisResponseHeader["location"],
                let newURL = URL(string: newLocation)
            {
                currentLocation = newURL
                continue
            }
            response = thisResponse
            break
        }
        
        guard let response = response else {
            throw AppStoreError.invalidResponse
        }

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
            throw AppStoreError.custom(failureType)
        }

        if response.songList.isEmpty {
            throw AppStoreError.invalidResponse
        }

        return response.songList[0]
    }

    public nonisolated
    func getDownloadInfo(
        account: Account,
        app: AppPackage
    ) async throws -> (url: String, sinfs: [Sinf], md5: String) {
        let item = try await fetchDownloadInfo(account: account, appID: app.id)

        guard let md5 = item.md5 else {
            throw AppStoreError.custom("Missing MD5 hash in download response", nil)
        }

        return (item.URL, item.sinfs, md5)
    }

    public nonisolated
    func download(
        account: Account,
        app: AppPackage,
        outputPath: String,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws {
        let item = try await fetchDownloadInfo(account: account, appID: app.id)

        let destinationPath = try resolveDestinationPath(app: app, path: outputPath)
        let tmpPath = "\(destinationPath).tmp"

        try await downloadFile(from: item.URL, to: tmpPath, progressHandler: progressHandler)

        try applyPatches(item: item, sourcePath: tmpPath, destinationPath: destinationPath)

        try FileManager.default.removeItem(atPath: tmpPath)
    }

    func downloadFile(from url: String, to path: String, progressHandler _: ((Double) -> Void)? = nil) async throws {
        guard let url = URL(string: url) else {
            throw AppStoreError.custom(String(localized: "invalid_url", bundle: .module))
        }

        let (downloadURL, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: downloadURL, to: URL(fileURLWithPath: path))
    }

    func resolveDestinationPath(app: AppPackage, path: String) throws -> String {
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

    private func applyPatches(item: DownloadItem, sourcePath: String, destinationPath: String) throws {
        try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath)
        try zipUtility.replicateSinf(inputPath: destinationPath, outputPath: destinationPath, sinfs: item.sinfs)
    }
}
