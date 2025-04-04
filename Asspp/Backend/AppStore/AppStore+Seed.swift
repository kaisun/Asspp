
//
//  AppStore+Seed.swift
//  Asspp
//
//  Created by 秋星桥 on 4/4/25.
//

import Foundation

extension AppStore {
    static func createSeed() -> String {
        "00:00:00:00:00:00"
            .components(separatedBy: ":")
            .map { _ in
                let randomHex = String(Int.random(in: 0 ... 255), radix: 16)
                return randomHex.count == 1 ? "0\(randomHex)" : randomHex
            }
            .joined(separator: ":")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ":", with: "")
            .uppercased()
    }
}
