//
//  Downloads+Request.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import AnyCodable
import ApplePackage
import Foundation

private let storeDir = {
    let ret = documentsDirectory.appendingPathComponent("Packages")
    try? FileManager.default.createDirectory(at: ret, withIntermediateDirectories: true)
    return ret
}()

extension Downloads {
    struct Request: Identifiable, Codable, Hashable {
        var id: UUID = .init()

        var account: Account
        var package: AppPackage

        var url: URL
        var md5: String
        var signatures: [Sinf]

        var creation: Date
        var targetLocation: URL {
            storeDir
                .appendingPathComponent(package.bundleID)
                .appendingPathComponent(package.version)
                .appendingPathComponent("\(md5)_\(id.uuidString)")
                .appendingPathExtension("ipa")
        }

        var runtime: Runtime = .init()

        init(
            account: Account,
            package: AppPackage,
            url: URL,
            md5: String,
            sinfs: [Sinf]
        ) {
            self.account = account
            self.package = package
            self.url = url
            self.md5 = md5
            signatures = sinfs
            creation = .init()
        }
    }
}

extension Downloads.Request {
    struct Runtime: Codable, Hashable {
        enum Status: String, Codable {
            case stopped
            case pending
            case downloading
            case verifying
            case completed
        }

        var status: Status = .stopped {
            didSet { if status != .downloading { speed = "" } }
        }

        var speed: String = ""
        var percent: Double = 0
        var error: String? = nil

        var progress: Progress {
            let p = Progress(totalUnitCount: 100)
            p.completedUnitCount = Int64(percent * 100)
            return p
        }
    }
}
