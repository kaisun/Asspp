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
            case pending
            case downloading
            case completed
            case failed
        }

        var status: Status = .pending
        var percent: Double = 0
        var error: String? = nil
        var speed: String = ""
    }
}
