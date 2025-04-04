//
//  EntityType.swift
//  ApplePackage
//
//  Created by 秋星桥 on 4/4/25.
//

import Foundation

public enum EntityType: String, Identifiable, CaseIterable, Codable {
    public var id: String { rawValue }

    case iPhone
    case iPad
    case macOS
}

extension EntityType {
    var searchParameterValue: String {
        switch self {
        case .iPhone:
            "software"
        case .iPad:
            "iPadSoftware"
        case .macOS:
            "macSoftware"
        }
    }
}
