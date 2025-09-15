//
//  Downloads+Logic.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation
import Logging

extension Downloads: URLSessionDownloadDelegate {
    func finalize(request: Request, url: URL) async {
        logger.info("[*] finalizing download for request id: \(request.id)")
        let targetLocation = request.targetLocation

        // If url is the same as targetLocation, no need to move
        let finalURL = (url == targetLocation) ? targetLocation : url

        do {
            if let md5 = request.md5 {
                logger.info("[*] verifying md5 checksum for request id: \(request.id)")
                let fileMD5 = md5File(url: finalURL)
                guard md5.lowercased() == fileMD5?.lowercased() else {
                    logger.error("[-] md5 checksum mismatch for request id: \(request.id)")
                    await report(error: NSError(domain: "MD5", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: String(localized: "The file's checksum does not match the expected value."),
                    ]), reqId: request.id)
                    return
                }
                logger.info("[+] md5 checksum verified for request id: \(request.id)")
            }

            // Only move if it's a temp file, don't remove existing target file for resume support
            if url != targetLocation {
                try? FileManager.default.createDirectory(
                    at: targetLocation.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try FileManager.default.moveItem(at: url, to: targetLocation)
            }

            await reportSuccess(reqId: request.id)
            logger.info("[+] download finalized successfully for request id: \(request.id)")
        } catch {
            logger.error("[-] finalization failed for request id: \(request.id), error: \(error.localizedDescription)")
            await report(error: error, reqId: request.id)
        }
    }

    func downloadWithProgress(from url: URL, to fileURL: URL, requestID: Request.ID) async throws {
        logger.info("[*] starting download with progress for url: \(url.host ?? "unknown")/\(url.lastPathComponent), request id: \(requestID)")

        // Check if file exists and get its size for resume
        var existingFileSize: Int64 = 0
        var shouldResume = false

        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                existingFileSize = attributes[.size] as? Int64 ?? 0
                shouldResume = existingFileSize > 0
                logger.info("[*] found existing file with size: \(existingFileSize) bytes, attempting resume")
            } catch {
                logger.warning("[!] failed to get file attributes: \(error.localizedDescription)")
                try? FileManager.default.removeItem(at: fileURL)
                existingFileSize = 0
                shouldResume = false
            }
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        var request = URLRequest(url: url)

        // Add Range header for resume if file exists
        if shouldResume {
            request.addValue("bytes=\(existingFileSize)-", forHTTPHeaderField: "Range")
            logger.info("[*] resuming download from byte: \(existingFileSize)")
        }

        let task = session.downloadTask(with: request)
        activeDownloads[requestID] = DownloadState(task: task, continuation: nil, lastBytes: existingFileSize, lastUpdate: Date())

        return try await withCheckedThrowingContinuation { continuation in
            if var state = activeDownloads[requestID] {
                state.continuation = continuation
                activeDownloads[requestID] = state
            }
            task.resume()
        }
    }

    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let requestID = activeDownloads.first(where: { $0.value.task == downloadTask })?.key,
              let state = activeDownloads[requestID] else { return }

        Task { @MainActor in
            if totalBytesExpectedToWrite > 0 {
                // For resume downloads, add existing file size to get correct progress
                let existingFileSize = state.lastBytes
                let totalProgress = existingFileSize + totalBytesWritten
                let totalExpected = existingFileSize + totalBytesExpectedToWrite

                let progress = Progress(totalUnitCount: totalExpected)
                progress.completedUnitCount = totalProgress
                await report(progress: progress, reqId: requestID)
            }

            let now = Date()
            guard var currentState = activeDownloads[requestID] else { return }
            let elapsed = now.timeIntervalSince(currentState.lastUpdate)

            if elapsed >= 0.5 {
                let speed = Int64(Double(totalBytesWritten - (currentState.lastBytes - state.lastBytes)) / elapsed)
                let speedStr = byteFormat(bytes: speed)
                await report(speed: speedStr, reqId: requestID)
                currentState.lastBytes = state.lastBytes + totalBytesWritten
                currentState.lastUpdate = now
                activeDownloads[requestID] = currentState
            }
        }
    }

    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let requestID = activeDownloads.first(where: { $0.value.task == downloadTask })?.key,
              let request = requests.first(where: { $0.id == requestID }),
              var state = activeDownloads[requestID] else { return }

        let targetURL = request.targetLocation

        do {
            // For resume downloads, we need to append the downloaded data to existing file
            if FileManager.default.fileExists(atPath: targetURL.path) {
                // Read existing file data
                let existingData = try Data(contentsOf: targetURL)
                // Read downloaded data
                let downloadedData = try Data(contentsOf: location)
                // Combine and write back
                let combinedData = existingData + downloadedData
                try combinedData.write(to: targetURL)
                logger.info("[+] appended downloaded data to existing file: \(targetURL.path)")
            } else {
                // First time download, just move the file
                try? FileManager.default.createDirectory(
                    at: targetURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try FileManager.default.moveItem(at: location, to: targetURL)
                logger.info("[+] moved downloaded file to target location: \(targetURL.path)")
            }
            state.moveError = nil
        } catch {
            logger.error("[-] failed to handle downloaded file: \(error.localizedDescription)")
            state.moveError = error
        }

        activeDownloads[requestID] = state
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask,
              let requestID = activeDownloads.first(where: { $0.value.task == downloadTask })?.key,
              let state = activeDownloads[requestID] else { return }
        activeDownloads.removeValue(forKey: requestID)

        Task { @MainActor in
            if let continuation = state.continuation {
                if let error = error ?? state.moveError {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func getContentInfo(from url: URL) async throws -> (contentLength: Int64, supportsRanges: Bool) {
        logger.info("[*] fetching content info for url: \(url.host ?? "unknown")/\(url.lastPathComponent)")
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("[-] invalid response format for content info")
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: String(localized: "The server returned an invalid response format.")])
        }

        let contentLength = httpResponse.expectedContentLength
        var supportsRanges = false
        for (key, value) in httpResponse.allHeaderFields {
            if String(describing: key).lowercased() == "accept-ranges",
               let s = value as? String,
               s.lowercased().contains("bytes")
            {
                supportsRanges = true
                break
            }
        }
        logger.info("[*] content info: length=\(contentLength), supportsranges=\(supportsRanges)")

        return (contentLength, supportsRanges)
    }
}
