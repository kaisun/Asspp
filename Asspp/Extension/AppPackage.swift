//
//  AppPackage.swift
//  Asspp
//
//  Created by 秋星桥 on 4/4/25.
//

import ApplePackage
import Foundation

extension AppPackage {
    private static let fmt: ByteCountFormatter = {
        let fmt = ByteCountFormatter()
        fmt.allowedUnits = .useAll
        fmt.countStyle = .file
        return fmt
    }()

    var oneLineDescription: String { [
        bundleID,
        version,
        Self.fmt.string(fromByteCount: Int64(fileSize) ?? 0),
    ].joined(separator: " ") }

    var displaySupportedDevicesIcon: String {
        var supports_iPhone = false
        var supports_iPad = false
        for device in supportedDevices {
            if device.lowercased().contains("iphone") {
                supports_iPhone = true
            }
            if device.lowercased().contains("ipad") {
                supports_iPad = true
            }
        }
        if supports_iPhone, supports_iPad {
            return "ipad.and.iphone"
        } else if supports_iPhone {
            return "iphone"
        } else if supports_iPad {
            return "ipad"
        } else {
            return "questionmark"
        }
    }
}
