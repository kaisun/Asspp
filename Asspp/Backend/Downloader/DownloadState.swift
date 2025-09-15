//
//  DownloadState.swift
//  Asspp
//
//  Created by qaq on 9/15/25.
//

import Foundation

struct DownloadState: Codable, Hashable, Equatable {
    enum Status: String, Codable, Equatable, Hashable {
        case pending
        case downloading
        case paused
        case completed
        case failed
    }

    var status: Status = .pending
    var percent: Double = 0
    var error: String? = nil
    var speed: String = ""
}

extension DownloadState {
    mutating func resetIfNotCompleted() {
        guard [.pending, .downloading].contains(status) else { return }
        status = .pending
        percent = 0
        error = nil
    }
}
