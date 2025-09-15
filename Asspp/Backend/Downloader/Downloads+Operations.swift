//
//  Downloads+Operations.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation
import Logging

@MainActor
private extension Downloads {
    func cleanRuntime(for requestID: Request.ID) {
        logger.info("[*] cleaning up existing download for request id: \(requestID)")

        if let state = activeDownloads[requestID] {
            state.continuation?.resume(throwing: CancellationError())
            state.task.cancel()
            activeDownloads.removeValue(forKey: requestID)
        }

        downloadTasks[requestID]?.cancel()
        downloadTasks[requestID] = nil
    }

    func createDownloadTask(for requestID: Request.ID, removeExists: Bool = false) async {
        guard let request = requests.first(where: { $0.id == requestID }) else {
            logger.warning("[!] request id: \(requestID) not found")
            return
        }

        let initialPercent = removeExists ? 0 : request.runtime.percent
        await updateRequestStatus(requestID, status: .pending, percent: initialPercent, error: nil)

        if removeExists { try? FileManager.default.removeItem(at: request.targetLocation) }

        let task = Task.detached { [self] in
            var retryCount = 0
            let maxRetries = 3

            while retryCount < maxRetries {
                do {
                    logger.info("[*] starting download \(requestID) attempt \(retryCount)")
                    try await downloadWithProgress(from: request.url, to: request.targetLocation, requestID: requestID)
                    try await finalize(request: request)
                    logger.info("[*] download completed successfully for request id: \(requestID)")
                    break
                } catch is CancellationError {
                    logger.info("[*] download cancelled for request id: \(requestID)")
                    break
                } catch {
                    retryCount += 1
                    logger.error("[-] download \(requestID) error \(error.localizedDescription) attempt \(retryCount)")
                    if retryCount >= maxRetries {
                        await report(error: error, reqId: requestID)
                        break
                    } else {
                        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds delay
                    }
                }
            }
        }

        downloadTasks[requestID] = task
        logger.info("[+] download task started for request id: \(requestID)")
    }
}

@MainActor
extension Downloads {
    func add(request: Request) async -> Request.ID {
        logger.info("[*] adding download request for url: \(request.url.host ?? "unknown")/\(request.url.lastPathComponent)")
        requests.append(request)
        return request.id
    }

    func suspend(requestID: Request.ID) async {
        logger.info("[*] suspending download request id: \(requestID)")

        guard let state = activeDownloads[requestID] else {
            logger.warning("[!] no active download found for request id: \(requestID)")
            return
        }

        let currentPercent = requests
            .first { $0.id == requestID }?
            .runtime
            .percent ?? 0

        state.task.cancel()
        state.continuation?.resume(throwing: CancellationError())

        activeDownloads.removeValue(forKey: requestID)

        downloadTasks[requestID]?.cancel()
        downloadTasks[requestID] = nil

        await updateRequestStatus(requestID, status: .paused, percent: currentPercent, error: nil)
    }

    func resume(requestID: Request.ID) async {
        logger.info("[*] resuming download request id: \(requestID)")
        let request = requests.first(where: { $0.id == requestID })
        guard let request else {
            logger.warning("[!] request id: \(requestID) not found")
            return
        }
        if request.runtime.status == .downloading {
            logger.info("[*] request id: \(requestID) is already downloading, no action taken")
            return
        }
        await createDownloadTask(for: requestID, removeExists: false)
    }

    func delete(request: Request) async {
        logger.info("[*] deleting download request id: \(request.id)")
        await suspend(requestID: request.id)
        requests.removeAll(where: { $0.id == request.id })
        try? FileManager.default.removeItem(at: request.targetLocation)
    }

    func restart(requestID: Request.ID) async {
        logger.info("[*] restarting download request id: \(requestID)")
        cleanRuntime(for: requestID)
        await createDownloadTask(for: requestID, removeExists: true)
    }
}
