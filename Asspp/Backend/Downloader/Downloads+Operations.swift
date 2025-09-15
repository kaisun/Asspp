//
//  Downloads+Operations.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation
import Logging

extension Downloads {
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
        state.task.cancel()
        activeDownloads.removeValue(forKey: requestID)
        await updateRequestStatus(requestID, status: .paused, percent: requests.first(where: { $0.id == requestID })?.runtime.percent ?? 0, error: nil)
        logger.info("[+] download suspended for request id: \(requestID)")
    }

    func cancel(requestID: Request.ID) async {
        logger.info("[*] cancelling download request id: \(requestID)")
        if let state = activeDownloads[requestID] {
            state.task.cancel()
            activeDownloads.removeValue(forKey: requestID)
        }
        if let asyncTask = downloadTasks[requestID] {
            asyncTask.cancel()
            downloadTasks[requestID] = nil
        }
        await updateRequestStatus(requestID, status: .failed, percent: 0, error: nil)
        if let request = requests.first(where: { $0.id == requestID }) {
            try? FileManager.default.removeItem(at: request.targetLocation)
            logger.info("[+] removed partial file for cancelled request id: \(requestID)")
        }
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

        // Start a new download
        await updateRequestStatus(requestID, status: .pending, percent: request.runtime.percent, error: nil)

        let task = Task {
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
                        await updateRequestStatus(requestID, status: .failed, percent: request.runtime.percent, error: error.localizedDescription)
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

    func delete(request: Request) async {
        logger.info("[*] deleting download request id: \(request.id)")
        await cancel(requestID: request.id)
        requests.removeAll(where: { $0.id == request.id })
        logger.info("[+] download request deleted id: \(request.id)")
    }
}
