//
//  Downloads+BatchOperations.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation
import Logging

// MARK: - Batch Operations Protocol

protocol BatchDownloadOperations {
    func resumeAll() async
    func suspendAll()
    func removeAll() async
    func clearCompleted() async
}

// MARK: - Utility Operations Protocol

protocol DownloadUtilities {
    func getRequestsByStatus(_ status: Downloads.Runtime.Status) -> [Downloads.Request]
    func getActiveDownloadCount() -> Int
    func getFailedDownloadCount() -> Int
    func getCompletedDownloadCount() -> Int
}

// MARK: - Batch Operations Extension

extension Downloads: BatchDownloadOperations, DownloadUtilities {
    // MARK: - Batch Operations

    func resumeAll() async {
        logger.info("[*] resuming all eligible downloads")

        let eligibleRequests = requests.filter { request in
            request.runtime.status != .downloading && request.runtime.status != .completed
        }

        for request in eligibleRequests {
            if request.runtime.status == .failed {
                await restart(requestID: request.id)
            } else {
                await resume(requestID: request.id)
            }
        }

        logger.info("[+] resume all operation completed")
    }

    func suspendAll() {
        logger.info("[*] suspending all active downloads")

        // Cancel all async tasks with proper cleanup
        for (requestID, task) in downloadTasks {
            task.cancel()
            downloadTasks[requestID] = nil
        }

        // Update status for downloading requests
        for index in requests.indices {
            if requests[index].runtime.status == .downloading {
                requests[index].runtime.status = .paused
            }
        }

        logger.info("[+] suspend all operation completed")
    }

    func removeAll() async {
        logger.info("[*] removing all downloads")

        suspendAll()

        // Remove all files with error handling
        for request in requests {
            try? FileManager.default.removeItem(at: request.targetLocation)
        }

        requests.removeAll()
        logger.info("[+] remove all operation completed")
    }

    func clearCompleted() async {
        logger.info("[*] clearing completed downloads")

        let completedCount = requests.count(where: { $0.runtime.status == .completed })
        requests.removeAll(where: { $0.runtime.status == .completed })

        logger.info("[+] cleared \(completedCount) completed downloads")
    }

    // MARK: - Utility Methods

    func getRequestsByStatus(_ status: Runtime.Status) -> [Request] {
        requests.filter { $0.runtime.status == status }
    }

    func getActiveDownloadCount() -> Int {
        downloadTasks.count
    }

    func getFailedDownloadCount() -> Int {
        getRequestsByStatus(.failed).count
    }

    func getCompletedDownloadCount() -> Int {
        getRequestsByStatus(.completed).count
    }
}
