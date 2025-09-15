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
    var requests: [Downloads.Request]

    var downloadTasks: [Downloads.Request.ID: Task<Void, Error>] = [:] {
        didSet { objectWillChange.send() }
    }

    // Add properties for URLSessionDownloadDelegate
    var activeDownloads: [Request.ID: DownloadState] = [:]

    struct DownloadState {
        var task: URLSessionDownloadTask
        var continuation: CheckedContinuation<Void, Error>?
        var lastBytes: Int64 = 0
        var lastUpdate: Date = .init()
        var moveError: Error?
        var isSuspended: Bool = false
    }

    var runningTaskCount: Int {
        requests.count(where: { $0.runtime.status == .downloading })
    }

    override init() {
        super.init()
        logger.info("[*] initializing downloads manager")
        let copy = requests
        Task {
            for req in copy {
                logger.info("[*] checking and updating status for existing request id: \(req.id)")
                await checkAndUpdateDownloadStatus(for: req)
            }
        }
        logger.info("[+] downloads manager initialized with \(copy.count) existing requests")
    }
}
