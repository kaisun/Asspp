//
//  Downloads+Request.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import AnyCodable // Moved to Request.swift

import ApplePackage
import Foundation

private let storeDir = {
    let ret = documentsDirectory.appendingPathComponent("Packages")
    try? FileManager.default.createDirectory(at: ret, withIntermediateDirectories: true)
    return ret
}()

extension Downloads {
    class Request: ObservableObject, Identifiable, Codable, Hashable, Equatable {
        @Published var id: UUID = .init()

        @Published var account: AppStore.UserAccount
        @Published var package: AppStore.AppPackage

        @Published var url: URL
        @Published var signatures: [ApplePackage.Sinf]
        @Published var metadata: [String: AnyCodable]

        @Published var creation: Date
        @Published var runtime: Runtime = .init()

        var targetLocation: URL {
            storeDir
                .appendingPathComponent(package.software.bundleID)
                .appendingPathComponent(package.software.version)
                .appendingPathComponent("\(id.uuidString)")
                .appendingPathExtension("ipa")
        }

        init(account: AppStore.UserAccount, package: AppStore.AppPackage, downloadOutput: ApplePackage.DownloadOutput) {
            self.account = account
            self.package = package
            url = URL(string: downloadOutput.downloadURL)!
            signatures = downloadOutput.sinfs
            creation = .init()
            metadata = [:] // Simplified
        }

        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            account = try container.decode(AppStore.UserAccount.self, forKey: .account)
            package = try container.decode(AppStore.AppPackage.self, forKey: .package)
            url = try container.decode(URL.self, forKey: .url)
            signatures = try container.decode([ApplePackage.Sinf].self, forKey: .signatures)
            metadata = try container.decode([String: AnyCodable].self, forKey: .metadata)
            creation = try container.decode(Date.self, forKey: .creation)
            runtime = try container.decode(Runtime.self, forKey: .runtime)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(account, forKey: .account)
            try container.encode(package, forKey: .package)
            try container.encode(url, forKey: .url)
            try container.encode(signatures, forKey: .signatures)
            try container.encode(metadata, forKey: .metadata)
            try container.encode(creation, forKey: .creation)
            try container.encode(runtime, forKey: .runtime)
        }

        private enum CodingKeys: String, CodingKey {
            case id, account, package, url, md5, signatures, metadata, creation, runtime
        }

        static func == (lhs: Request, rhs: Request) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(account)
            hasher.combine(package)
            hasher.combine(url)
            hasher.combine(signatures)
            hasher.combine(metadata)
            hasher.combine(creation)
            hasher.combine(runtime)
        }
    }
}
