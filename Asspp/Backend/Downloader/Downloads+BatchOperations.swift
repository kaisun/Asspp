//
//  Downloads+BatchOperations.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation
import Logging

extension Downloads {
    func resumeAll() async {
        logger.info("[*] resuming all eligible downloads")
        for request in requests where request.runtime.status != .downloading && request.runtime.status != .completed {
            await resume(requestID: request.id)
        }
        logger.info("[+] resume all operation completed")
    }

    func suspendAll() {
        logger.info("[*] suspending all active downloads")
        for (requestID, task) in downloadTasks {
            task.cancel()
            downloadTasks[requestID] = nil
        }
        for i in requests.indices {
            if requests[i].runtime.status == .downloading {
                requests[i].runtime.status = .stopped
            }
        }
        logger.info("[+] suspend all operation completed")
    }

    func removeAll() async {
        logger.info("[*] removing all downloads")
        suspendAll()
        for request in requests {
            try? FileManager.default.removeItem(at: request.targetLocation)
        }
        requests.removeAll()
        logger.info("[+] remove all operation completed")
    }

    func clearCompleted() async {
        logger.info("[*] clearing completed downloads")
        requests.removeAll(where: { $0.runtime.status == .completed })
        logger.info("[+] cleared completed downloads")
    }
}
