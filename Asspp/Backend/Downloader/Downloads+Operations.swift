//
//  Downloads+Operations.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation
import Logging

extension Downloads {
    // MARK: - Private Helper Methods

    private func cleanupExistingDownload(for requestID: Request.ID) {
        logger.info("[*] cleaning up existing download for request id: \(requestID)")

        // Cancel active download task with proper error handling
        if let state = activeDownloads[requestID] {
            state.continuation?.resume(throwing: CancellationError())
            state.task.cancel()
            activeDownloads.removeValue(forKey: requestID)
        }

        // Cancel async task
        downloadTasks[requestID]?.cancel()
        downloadTasks[requestID] = nil
    }

    private func createDownloadTask(for requestID: Request.ID, resetProgress: Bool = false) async {
        guard let request = requests.first(where: { $0.id == requestID }) else {
            logger.warning("[!] request id: \(requestID) not found")
            return
        }

        // Update status and progress with early return pattern
        let initialPercent = resetProgress ? 0 : request.runtime.percent
        await updateRequestStatus(requestID, status: .pending, percent: initialPercent, error: nil)

        // Remove partial file if resetting
        if resetProgress {
            try? FileManager.default.removeItem(at: request.targetLocation)
        }

        // Create download task with proper error handling
        let task = Task { [weak self] in
            guard let self else { return }

            var retryCount = 0
            let maxRetries = 3

            while retryCount < maxRetries {
                do {
                    logger.info("[*] starting download task for request id: \(requestID) (attempt \(retryCount + 1)/\(maxRetries))")
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("AssppDownload_\(requestID.uuidString).ipa")
                    try await downloadWithProgress(from: request.url, to: tempURL, requestID: requestID)
                    await finalize(request: request, url: tempURL)
                    logger.info("[+] download completed successfully for request id: \(requestID)")
                    break
                } catch is CancellationError {
                    logger.info("[+] download cancelled for request id: \(requestID)")
                    break
                } catch {
                    retryCount += 1
                    if retryCount >= maxRetries {
                        logger.error("[-] download failed after \(maxRetries) retries for request id: \(requestID), error: \(error.localizedDescription)")
                        await updateRequestStatus(requestID, status: .failed, percent: resetProgress ? 0 : request.runtime.percent, error: error.localizedDescription)
                    } else {
                        logger.warning("[!] download failed, retrying (\(retryCount)/\(maxRetries)) for request id: \(requestID), error: \(error.localizedDescription)")
                        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds delay
                    }
                }
            }
        }

        downloadTasks[requestID] = task
        logger.info("[+] download task started for request id: \(requestID)")
    }

    // MARK: - Public Operations

    func add(request: Request) async -> Request.ID {
        logger.info("[*] adding download request for url: \(request.url.host ?? "unknown")/\(request.url.lastPathComponent)")
        requests.append(request)
        await checkAndUpdateDownloadStatus(for: request)
        logger.info("[+] download request added with id: \(request.id)")
        return request.id
    }

    func suspend(requestID: Request.ID) async {
        logger.info("[*] suspending download request id: \(requestID)")

        guard let state = activeDownloads[requestID] else {
            logger.warning("[!] no active download found for request id: \(requestID)")
            return
        }

        // Get current progress before cleanup
        let currentPercent = requests.first(where: { $0.id == requestID })?.runtime.percent ?? 0

        // Resume continuation with cancellation error before canceling task
        state.continuation?.resume(throwing: CancellationError())
        state.task.cancel()
        activeDownloads.removeValue(forKey: requestID)

        // Also cancel and remove the async task
        downloadTasks[requestID]?.cancel()
        downloadTasks[requestID] = nil

        await updateRequestStatus(requestID, status: .paused, percent: currentPercent, error: nil)
        logger.info("[+] download suspended for request id: \(requestID)")
    }

    func cancel(requestID: Request.ID) async {
        logger.info("[*] cancelling download request id: \(requestID)")

        cleanupExistingDownload(for: requestID)
        await updateRequestStatus(requestID, status: .failed, percent: 0, error: nil)

        guard let request = requests.first(where: { $0.id == requestID }) else {
            return
        }

        try? FileManager.default.removeItem(at: request.targetLocation)
        logger.info("[+] removed partial file for cancelled request id: \(requestID)")
        logger.info("[+] download cancelled for request id: \(requestID)")
    }

    func resume(requestID: Request.ID) async {
        logger.info("[*] resuming download request id: \(requestID)")

        guard let request = requests.first(where: { $0.id == requestID }),
              request.runtime.status != .downloading
        else {
            logger.warning("[!] request id: \(requestID) is already downloading or invalid")
            return
        }

        await createDownloadTask(for: requestID, resetProgress: false)
    }

    func delete(request: Request) async {
        logger.info("[*] deleting download request id: \(request.id)")
        await cancel(requestID: request.id)
        requests.removeAll(where: { $0.id == request.id })
        logger.info("[+] download request deleted id: \(request.id)")
    }

    func restart(requestID: Request.ID) async {
        logger.info("[*] restarting download request id: \(requestID)")

        guard requests.contains(where: { $0.id == requestID }) else {
            logger.warning("[!] request id: \(requestID) not found")
            return
        }

        // Clean up existing download and start fresh
        cleanupExistingDownload(for: requestID)
        await createDownloadTask(for: requestID, resetProgress: true)
    }
}
