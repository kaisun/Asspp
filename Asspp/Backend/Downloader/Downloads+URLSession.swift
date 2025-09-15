//
//  Downloads+URLSession.swift
//  Asspp
//
//  Created by qaq on 9/15/25.
//

import Foundation

extension Downloads: URLSessionDataDelegate {
    func urlSession(_: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let requestID = activeDownloads.first(where: { $0.value.task == dataTask })?.key,
              var state = activeDownloads[requestID] else { return }

        do {
            assert(state.fileHandle != nil)
            try state.fileHandle?.write(contentsOf: data)
            let bytesWritten = Int64(data.count)
            state.lastBytes += bytesWritten

            Task { @MainActor in
                if let expectedContentLength = dataTask.response?.expectedContentLength,
                   expectedContentLength > 0
                {
                    let totalExpected = state.lastBytes + expectedContentLength
                    let progress = Progress(totalUnitCount: totalExpected)
                    progress.completedUnitCount = state.lastBytes
                    await report(progress: progress, reqId: requestID)
                }

                let now = Date()
                let elapsed = now.timeIntervalSince(state.lastUpdate)
                if elapsed >= 0.5 {
                    let speed = Int64(Double(bytesWritten) / elapsed)
                    let speedStr = byteFormat(bytes: speed)
                    await report(speed: speedStr, reqId: requestID)
                    state.lastUpdate = now
                    activeDownloads[requestID] = state
                }
            }
        } catch {
            logger.error("[-] failed to write data to file: \(error.localizedDescription)")
            state.moveError = error
            activeDownloads[requestID] = state
        }
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let requestID = activeDownloads.first(where: { $0.value.task == task })?.key,
              let state = activeDownloads[requestID] else { return }
        try? state.fileHandle?.close()
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
        guard var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NSError(
                domain: "InvalidURL",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: String(localized: "The provided URL is invalid."),
                ]
            )
        }
        comps.queryItems = []
        guard let fileName = comps.url?.lastPathComponent else {
            throw NSError(
                domain: "InvalidURL",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: String(localized: "The provided URL is invalid."),
                ]
            )
        }
        logger.info("[*] fetching head for \(fileName)")

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("[-] invalid response format for content info")
            throw NSError(
                domain: "InvalidResponse",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: String(localized: "The server returned an invalid response format."),
                ]
            )
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
        logger.info("[*] HEAD: length=\(contentLength), supportsranges=\(supportsRanges)")

        return (contentLength, supportsRanges)
    }
}
