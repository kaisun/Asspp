//
//  Downloads+Report.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation
import Logging

extension Downloads {
    func alter(reqID: Request.ID, _ callback: @escaping (inout Request) -> Void) async {
        guard let index = requests.firstIndex(where: { $0.id == reqID }) else {
            logger.warning("[!] request id not found for alteration: \(reqID)")
            return
        }
        var req = requests[index]
        let hashValue = req.hashValue
        callback(&req)
        guard req.hashValue != hashValue else {
            logger.debug("[=] request unchanged after alteration: \(reqID)")
            return
        }
        requests[index] = req
    }

    func reportValidating(reqId: Request.ID) async {
        logger.info("[*] reporting validating status for request id: \(reqId)")
        await alter(reqID: reqId) { req in
            req.runtime.status = .downloading
        }
    }

    func reportSuccess(reqId: Request.ID) async {
        logger.info("[+] reporting success for request id: \(reqId)")
        await alter(reqID: reqId) { req in
            req.runtime.status = .completed
            req.runtime.percent = 1
            req.runtime.error = nil
        }
    }

    func report(error: Error?, reqId: Request.ID) async {
        logger.error("[-] reporting error for request id: \(reqId), error: \(error?.localizedDescription ?? "unknown error")")
        logger.error("[-] call stack: \(Thread.callStackSymbols.joined(separator: "\n"))")
        let error = error ?? NSError(domain: "DownloadManager", code: -1, userInfo: [
            NSLocalizedDescriptionKey: String(localized: "An unknown error occurred during the download process."),
        ])
        await alter(reqID: reqId) { req in
            req.runtime.error = error.localizedDescription
            req.runtime.status = .failed
        }
    }

    func report(progress: Progress, reqId: Request.ID) async {
        await alter(reqID: reqId) { req in
            req.runtime.percent = progress.fractionCompleted
            req.runtime.status = .downloading
            req.runtime.error = nil
        }
    }

    func report(speed: String, reqId: Request.ID) async {
        await alter(reqID: reqId) { $0.runtime.speed = speed }
    }
}
