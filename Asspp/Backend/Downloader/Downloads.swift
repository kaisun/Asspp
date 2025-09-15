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

class Downloads: NSObject, ObservableObject {
    @MainActor
    static let this = Downloads()

    @MainActor
    @PublishedPersist(key: "DownloadRequests", defaultValue: [])
    var requests: [Downloads.Request]

    var downloadTasks: [Downloads.Request.ID: Task<Void, Error>] = [:] {
        didSet { objectWillChange.send() }
    }

    // Add properties for URLSessionDownloadDelegate
    var activeDownloads: [Request.ID: DownloadState] = [:]

    struct DownloadState {
        var task: URLSessionTask
        var continuation: CheckedContinuation<Void, Error>?
        var lastBytes: Int64 = 0
        var lastUpdate: Date = .init()
        var moveError: Error?
        var isSuspended: Bool = false
        var fileHandle: FileHandle?
    }

    @MainActor
    var runningTaskCount: Int {
        requests.count(where: { $0.runtime.status == .downloading })
    }

    @MainActor
    override init() {
        super.init()
    }
}
