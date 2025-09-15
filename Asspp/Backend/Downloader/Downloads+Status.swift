//
//  Downloads+Status.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation

@MainActor
extension Downloads {
    func updateRequestStatus(
        _ requestID: Downloads.Request.ID,
        status: Runtime.Status,
        percent: Double,
        error: String?
    ) async {
        guard let index = requests.firstIndex(where: { $0.id == requestID }) else { return }
        requests[index].runtime.status = status
        requests[index].runtime.percent = percent
        requests[index].runtime.error = error
    }

    func isCompleted(for request: Request) -> Bool {
        request.runtime.status == .completed
    }
}

private enum FileValidationResult {
    case valid
    case invalid
    case unableToVerify
    case empty
}
