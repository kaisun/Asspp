//
//  AppStore+Rotate.swift
//  Asspp
//
//  Created by 秋星桥 on 4/4/25.
//

import ApplePackage
import Foundation

extension AppStore {
    @discardableResult
    func rotate(id: Account.ID) async throws -> Account? {
        guard let account = accounts.first(where: { $0.id == id }) else { return nil }

        let newAccount = try await service.login(
            email: account.email,
            password: account.password,
            authCode: ""
        )

        let countryCode = try service.storefront.countryCodeLookup(
            storeFront: newAccount.storeFront
        )

        let updatedAccount = Account(
            email: account.email,
            password: account.password,
            countryCode: countryCode,
            storeResponse: newAccount
        )

        save(email: account.email, account: updatedAccount)
        return updatedAccount
    }
}
