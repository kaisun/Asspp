//
//  Downloads+Logic.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import ApplePackage
import Foundation
import Logging

extension Downloads {
    nonisolated func finalize(request: Request) async throws {
        logger.info("[*] finalizing download for request id: \(request.id)")
        let targetLocation = request.targetLocation

        let signatures = request.signatures
        try await ApplePackage.SignatureInjector.inject(sinfs: signatures, into: targetLocation.path)

        await reportSuccess(reqId: request.id)
    }

    func downloadWithProgress(from url: URL, to fileURL: URL, requestID: Request.ID) async throws {
        logger.info("[*] starting download with progress for url: \(url.host ?? "unknown")/\(url.lastPathComponent), request id: \(requestID)")

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

        // Create directory if needed
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // Open file for writing (append if resuming)
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        if shouldResume {
            try fileHandle.seekToEnd()
        } else {
            try fileHandle.truncate(atOffset: 0)
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        var request = URLRequest(url: url)

        if shouldResume {
            request.addValue("bytes=\(existingFileSize)-", forHTTPHeaderField: "Range")
            logger.info("[*] resuming download from byte: \(existingFileSize)")
        }

        let task = session.dataTask(with: request)
        activeDownloads[requestID] = DownloadState(
            task: task,
            continuation: nil,
            lastBytes: existingFileSize,
            lastUpdate: Date(),
            fileHandle: fileHandle
        )

        return try await withCheckedThrowingContinuation { continuation in
            if var state = activeDownloads[requestID] {
                state.continuation = continuation
                activeDownloads[requestID] = state
            }
            task.resume()
        }
    }
}
