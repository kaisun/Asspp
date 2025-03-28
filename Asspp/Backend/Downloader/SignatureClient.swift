//
//  SignatureClient.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import AnyCodable
import ApplePackage
import Foundation

class SignatureClient {
    let fileManager: FileManager
    let filePath: String

    init(fileManager: FileManager, filePath: String) {
        self.fileManager = fileManager
        self.filePath = filePath
    }

    func appendMetadata(email: String, metadata _: AnyCodable) throws {
        // 实现将元数据附加到文件的逻辑
        // 这里简化实现，实际应根据需求具体实现
        print("Appending metadata for \(email) to \(filePath)")
    }

    func appendMetadata(item: StoreResponse.Item, email: String) throws {
        try appendMetadata(email: email, metadata: item.metadata)
    }

    func appendSignatures(sinfs: [Sinf]) throws {
        // 实现将签名附加到文件的逻辑
        // 这里简化实现，实际应根据需求具体实现
        print("Appending \(sinfs.count) signatures to \(filePath)")
    }

    func appendSignature(item: StoreResponse.Item) throws {
        let sinfs = item.signatures.map {
            // TODO: FIX
            Sinf(id: .init($0.hashValue), data: $0.data, provider: $0.provider)
        }
        try appendSignatures(sinfs: sinfs)
    }
}
