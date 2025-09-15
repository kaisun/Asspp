//
//  Downloads.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import AnyCodable
import ApplePackage
import Combine
import Foundation
import Logging

@MainActor
class Downloads: NSObject, ObservableObject {
    static let this = Downloads()

    @PublishedPersist(key: "DownloadRequests", defaultValue: [])
    var requests: [PackageManifest]

    var runningTaskCount: Int {
        requests.count(where: { $0.state.status == .downloading })
    }

    override init() {
        super.init()
        for idx in requests.indices {
            requests[idx].state.resetIfNotCompleted()
        }
    }

    func add(request: PackageManifest) async -> PackageManifest {
        logger.info("adding download request for url: \(request.url.host ?? "unknown")/\(request.url.lastPathComponent)")
        requests.append(request)
        return request
    }

    func suspend(request: PackageManifest) async {
        logger.info("suspending download request id: \(request)")
    }

    func resume(request: PackageManifest) async {
        logger.info("resuming download request id: \(request)")
    }

    func delete(request: PackageManifest) async {
        logger.info("deleting download request id: \(request)")
        await suspend(request: request)
        request.delete()
        requests.removeAll(where: { $0.id == request.id })
    }

    func restart(request: PackageManifest) async {
        logger.info("restarting download request id: \(request.id)")
    }

    func removeAll() {
        requests.forEach { $0.delete() }
        requests.removeAll()
    }
}
