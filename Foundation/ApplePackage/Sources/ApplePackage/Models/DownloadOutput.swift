//
//  DownloadOutput.swift
//  ApplePackage
//
//  Created by qaq on 9/15/25.
//

import Foundation

public struct DownloadOutput: Codable, Hashable, Equatable, Sendable {
    public var downloadURL: String
    public var sinfs: [Sinf]
    public var hashMD5: String?
    public var bundleShortVersionString: String?
    public var bundleVersion: String?

    public init(
        downloadURL: String,
        sinfs: [Sinf],
        hashMD5: String? = nil,
        bundleShortVersionString: String? = nil,
        bundleVersion: String? = nil
    ) {
        self.downloadURL = downloadURL
        self.sinfs = sinfs
        self.hashMD5 = hashMD5
        self.bundleShortVersionString = bundleShortVersionString
        self.bundleVersion = bundleVersion
    }
}
