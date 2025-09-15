//
//  Downloads+Batch.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation
import Logging

@MainActor
extension Downloads {
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
    }

    func suspendAll() {
        logger.info("[*] suspending all active downloads")
        for (requestID, task) in downloadTasks {
            task.cancel()
            downloadTasks[requestID] = nil
        }
        for index in requests.indices {
            if requests[index].runtime.status == .downloading {
                requests[index].runtime.status = .paused
            }
        }
    }

    func removeAll() async {
        logger.info("[*] removing all downloads")
        suspendAll()
        for request in requests {
            try? FileManager.default.removeItem(at: request.targetLocation)
        }
        requests.removeAll()
    }

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
