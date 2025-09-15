//
//  Downloads+Utils.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation

private let byteFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useAll]
    formatter.countStyle = .file
    return formatter
}()

extension Downloads {
    func byteFormat(bytes: Int64) -> String {
        byteFormatter.string(fromByteCount: bytes)
    }

    func downloadRequest(forArchive archive: AppStore.AppPackage) -> Request? {
        requests.first(where: { $0.package.id == archive.id })
    }
}
