//
//  Downloads+Runtime.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation

extension Downloads {
    struct Runtime: Codable, Hashable {
        enum Status: String, Codable {
            case stopped
            case pending
            case downloading
            case verifying
            case completed
            case cancelled
        }

        var status: Status = .stopped {
            didSet { if status != .downloading { speed = "" } }
        }

        var speed: String = ""
        var percent: Double = 0
        var error: String? = nil

        var progress: Progress {
            let p = Progress(totalUnitCount: 100)
            p.completedUnitCount = Int64(percent * 100)
            return p
        }
    }
}
