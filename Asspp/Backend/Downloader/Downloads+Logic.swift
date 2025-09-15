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

        do {
            if let md5 = request.md5 {
                logger.info("[*] verifying md5 checksum for request id: \(request.id)")
                let fileMD5 = md5File(url: url)
                guard md5.lowercased() == fileMD5?.lowercased() else {
                    logger.error("[-] md5 checksum mismatch for request id: \(request.id)")
                    await report(error: NSError(domain: "MD5", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: String(localized: "The file's checksum does not match the expected value."),
                    ]), reqId: request.id)
                    return
                }
                logger.info("[+] md5 checksum verified for request id: \(request.id)")
            }

            try? FileManager.default.removeItem(at: targetLocation)
            try? FileManager.default.createDirectory(
                at: targetLocation.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try FileManager.default.moveItem(at: url, to: targetLocation)

            await reportSuccess(reqId: request.id)
            logger.info("[+] download finalized successfully for request id: \(request.id)")
        } catch {
            logger.error("[-] finalization failed for request id: \(request.id), error: \(error.localizedDescription)")
            await report(error: error, reqId: request.id)
        }
    }

    func downloadWithProgress(from url: URL, to fileURL: URL, requestID: Request.ID) async throws {
        logger.info("[*] starting download with progress for url: \(url.host ?? "unknown")/\(url.lastPathComponent), request id: \(requestID)")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let request = URLRequest(url: url)
        let task = session.downloadTask(with: request)
        downloadTaskToRequestID[task] = requestID
        lastDownloadedBytes[requestID] = 0
        lastSpeedUpdate[requestID] = Date()

        return try await withCheckedThrowingContinuation { continuation in
            downloadContinuations[requestID] = continuation
            task.resume()
        }
    }

    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let requestID = downloadTaskToRequestID[downloadTask] else { return }

        Task {
            let progress = Progress(totalUnitCount: totalBytesExpectedToWrite)
            progress.completedUnitCount = totalBytesWritten
            await report(progress: progress, reqId: requestID)

            let now = Date()
            let lastBytes = lastDownloadedBytes[requestID] ?? 0
            let lastUpdate = lastSpeedUpdate[requestID] ?? now
            let elapsed = now.timeIntervalSince(lastUpdate)
            if elapsed > 0 {
                let speed = Int64(Double(totalBytesWritten - lastBytes) / elapsed)
                let speedStr = byteFormat(bytes: speed)
                await report(speed: speedStr, reqId: requestID)
                logger.debug("[?] progress update: \(progress.fractionCompleted * 100)%, speed: \(speedStr), request id: \(requestID)")
            }
            lastDownloadedBytes[requestID] = totalBytesWritten
            lastSpeedUpdate[requestID] = now
        }
    }

    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo _: URL) {
        guard let requestID = downloadTaskToRequestID[downloadTask] else { return }
        downloadTaskToRequestID.removeValue(forKey: downloadTask)

        if let continuation = downloadContinuations[requestID] {
            downloadContinuations.removeValue(forKey: requestID)
            continuation.resume(returning: ())
        }
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask, let requestID = downloadTaskToRequestID[downloadTask] else { return }
        downloadTaskToRequestID.removeValue(forKey: downloadTask)

        if let continuation = downloadContinuations[requestID] {
            downloadContinuations.removeValue(forKey: requestID)
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: ())
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
