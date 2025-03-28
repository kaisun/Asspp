//
//  StoreResponse.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import AnyCodable
import ApplePackage
import Foundation

struct StoreResponse: Codable {
    struct Item: Codable {
        let url: URL
        let md5: String
        let signatures: [Signature]
        let metadata: AnyCodable

        init(url: URL, md5: String, signatures: [Signature], metadata: [String: Any]) {
            self.url = url
            self.md5 = md5
            self.signatures = signatures
            self.metadata = .init(metadata)
        }

        struct Signature: Codable, Hashable {
            let data: Data
            let provider: String
        }
    }
}

extension StoreResponse.Item.Signature {
    static func from(sinf: Sinf) -> Self {
        StoreResponse.Item.Signature(data: sinf.data, provider: sinf.provider)
    }
}

extension StoreResponse.Item {
    static func from(url: String, md5: String?, sinfs: [Sinf], metadata: [String: AnyCodable]) -> Self {
        let signatures = sinfs.map { StoreResponse.Item.Signature.from(sinf: $0) }
        let metadataDict = metadata.reduce(into: [String: Any]()) { result, entry in
            result[entry.key] = entry.value.value
        }
        return StoreResponse.Item(
            url: URL(string: url)!,
            md5: md5 ?? "",
            signatures: signatures,
            metadata: metadataDict
        )
    }
}
