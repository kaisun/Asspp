//
//  Downloads+Logic.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation
import Logging

extension Downloads {
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

            // Simplified, no metadata for now
            await reportSuccess(reqId: request.id)
            logger.info("[+] download finalized successfully for request id: \(request.id)")
        } catch {
            logger.error("[-] finalization failed for request id: \(request.id), error: \(error.localizedDescription)")
            await report(error: error, reqId: request.id)
        }
    }

    func downloadWithProgress(from url: URL, to fileURL: URL, requestID: Request.ID) async throws {
        logger.info("[*] starting download with progress for url: \(url.host ?? "unknown")/\(url.lastPathComponent), request id: \(requestID)")

        let (headContentLength, supportsRanges) = try await getContentInfo(from: url)
        logger.info("[*] content info retrieved: length=\(headContentLength), supportsranges=\(supportsRanges), request id: \(requestID)")

        var startByte: Int64
        if supportsRanges, FileManager.default.fileExists(atPath: fileURL.path) {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            startByte = attributes[.size] as? Int64 ?? 0
            logger.info("[*] resuming from byte: \(startByte), request id: \(requestID)")
        } else {
            startByte = 0
            logger.info("[*] starting fresh download, request id: \(requestID)")
        }

        var request = URLRequest(url: url)
        if startByte > 0 {
            request.setValue("bytes=\(startByte)-", forHTTPHeaderField: "Range")
            logger.info("[*] using range header: bytes=\(startByte)-, request id: \(requestID)")
        }

        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not an HTTP response"])
        }
        guard 200 ... 299 ~= httpResponse.statusCode || httpResponse.statusCode == 206 else {
            logger.error("[-] http error: status code \(httpResponse.statusCode), request id: \(requestID)")
            throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: nil)
        }
        logger.info("[+] http response ok, starting data transfer, request id: \(requestID)")

        // Determine total length to report accurate progress, prefer HEAD; fallback to Content-Range total
        var totalLength = headContentLength
        if totalLength <= 0 {
            if let contentRange = httpResponse.value(forHTTPHeaderField: "Content-Range")?.lowercased(),
               let slashIndex = contentRange.lastIndex(of: "/"),
               let totalStr = String(contentRange[contentRange.index(after: slashIndex)...]).split(separator: ";").first,
               let parsedTotal = Int64(totalStr)
            {
                totalLength = parsedTotal
                logger.info("[*] total length resolved from Content-Range: \(totalLength)")
            }
        }

        let fileHandle: FileHandle
        if startByte > 0, FileManager.default.fileExists(atPath: fileURL.path) {
            // If server didn't honor range request, restart from scratch to avoid corrupt file.
            if httpResponse.statusCode != 206 {
                logger.info("[*] server did not return 206 for range request, restarting download from 0, request id: \(requestID)")
                startByte = 0
                // Clean up existing partial file
                try? FileManager.default.removeItem(at: fileURL)
            }
            // If remote file shrank, also restart
            if totalLength > 0, startByte > totalLength {
                logger.info("[*] local partial exceeds remote size (local=\(startByte), remote=\(totalLength)), restarting from 0, request id: \(requestID)")
                startByte = 0
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        if startByte > 0, FileManager.default.fileExists(atPath: fileURL.path) {
            fileHandle = try FileHandle(forWritingTo: fileURL)
            try fileHandle.seek(toOffset: UInt64(startByte))
        } else {
            try? FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            // Create/truncate file
            if FileManager.default.fileExists(atPath: fileURL.path) {
                // Truncate existing file to zero if present
                fileHandle = try FileHandle(forWritingTo: fileURL)
                try fileHandle.truncate(atOffset: 0)
            } else {
                let success = FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
                guard success else {
                    throw NSError(domain: "FileCreationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create file at path: \(fileURL.path)"])
                }
                fileHandle = try FileHandle(forWritingTo: fileURL)
            }
        }

        defer {
            try? fileHandle.close()
        }

        var downloadedBytes: Int64 = startByte
        var lastProgressUpdate = Date()
        let progressUpdateInterval: TimeInterval = 0.5
        var lastDownloadedBytes: Int64 = startByte
        var lastSpeedUpdate = Date()

        // Update initial status with proper percent based on resume progress
        let initialPercent: Double = if totalLength > 0 {
            min(1.0, max(0.0, Double(downloadedBytes) / Double(totalLength)))
        } else {
            0
        }
        await updateRequestStatus(requestID, status: .downloading, percent: initialPercent, error: nil)

        let chunkSize = 16 * 1024 * 1024 // 16MB
        var buffer = Data()
        buffer.reserveCapacity(chunkSize)

        for try await byte in asyncBytes {
            // Check if task is cancelled
            try Task.checkCancellation()

            buffer.append(byte)
            downloadedBytes += 1

            if buffer.count >= chunkSize {
                try fileHandle.write(contentsOf: buffer)
                buffer.removeAll(keepingCapacity: true)
            }

            let now = Date()
            if now.timeIntervalSince(lastProgressUpdate) >= progressUpdateInterval {
                // Flush small remaining buffer periodically to reflect progress on disk
                if !buffer.isEmpty {
                    try fileHandle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }

                let progress = Progress(totalUnitCount: totalLength)
                progress.completedUnitCount = downloadedBytes
                await report(progress: progress, reqId: requestID)

                let elapsed = now.timeIntervalSince(lastSpeedUpdate)
                if elapsed > 0 {
                    let speed = Int64(Double(downloadedBytes - lastDownloadedBytes) / elapsed)
                    let speedStr = byteFormat(bytes: speed)
                    await report(speed: speedStr, reqId: requestID)
                    logger.debug("[?] progress update: \(progress.fractionCompleted * 100)%, speed: \(speedStr), request id: \(requestID)")
                }

                lastProgressUpdate = now
                lastDownloadedBytes = downloadedBytes
                lastSpeedUpdate = now
            }
        }

        // Final flush
        if !buffer.isEmpty {
            try fileHandle.write(contentsOf: buffer)
            buffer.removeAll(keepingCapacity: false)
        }

        let progress = Progress(totalUnitCount: totalLength)
        progress.completedUnitCount = downloadedBytes
        await report(progress: progress, reqId: requestID)
        logger.info("[+] download data transfer completed, request id: \(requestID)")

        if totalLength > 0, downloadedBytes != totalLength {
            throw NSError(
                domain: "ContentLengthMismatch",
                code: 0,
                userInfo: [
                    NSLocalizedDescriptionKey: "Downloaded \(downloadedBytes) bytes, expected \(totalLength) bytes",
                ]
            )
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
