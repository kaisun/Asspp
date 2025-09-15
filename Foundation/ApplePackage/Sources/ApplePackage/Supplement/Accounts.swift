//
//  Accounts.swift
//  ApplePackage
//
//  Created by qaq on 9/15/25.
//

import CryptoKit
import Foundation

public func saveLoginAccount(_ account: Account, for email: String) {
    let fileURL = Configuration.accountPath(for: email)
        .appendingPathComponent("account.json")
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(account)
    try! data.write(to: fileURL)
}

public func withAccount<T>(email: String, _ body: (inout Account) async throws -> T) async throws -> T {
    var account: Account = try {
        let fileURL = Configuration.accountPath(for: email)
            .appendingPathComponent("account.json")
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Account.self, from: data)
    }()
    defer { saveLoginAccount(account, for: email) }
    return try await body(&account)
}
