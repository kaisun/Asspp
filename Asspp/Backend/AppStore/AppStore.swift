//
//  AppStore.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Combine
import Foundation

class AppStore: ObservableObject {
    struct Account: Codable, Identifiable, Hashable {
        var id: String { email }

        var email: String
        var password: String
        var countryCode: String
        var storeResponse: ApplePackage.Account
    }

    var cancellables: Set<AnyCancellable> = .init()

    @PublishedPersist(key: "DeviceSeedAddress", defaultValue: "")
    var deviceSeedAddress: String

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

    @PublishedPersist(key: "Accounts", defaultValue: [])
    var accounts: [Account]

    @PublishedPersist(key: "DemoMode", defaultValue: false)
    var demoMode: Bool

    static let this = AppStore()
    private var appStoreService: AppStoreService

    private init() {
        appStoreService = AppStoreService(guid: Self.createSeed())

        $deviceSeedAddress
            .removeDuplicates()
            .sink { [weak self] input in
                print("[*] updating guid \(input) as the seed")
                if !input.isEmpty {
                    self?.appStoreService = AppStoreService(guid: input)
                }
            }
            .store(in: &cancellables)
    }

    func setupGUID() {
        if deviceSeedAddress.isEmpty { deviceSeedAddress = Self.createSeed() }
        assert(!deviceSeedAddress.isEmpty)
        deviceSeedAddress = deviceSeedAddress
    }

    @discardableResult
    func save(email: String, password _: String, account: Account) -> Account {
        accounts = accounts
            .filter { $0.email.lowercased() != email.lowercased() }
            + [account]
        return account
    }

    func delete(id: Account.ID) {
        accounts = accounts.filter { $0.id != id }
    }

    @discardableResult
    func rotate(id: Account.ID) async throws -> Account? {
        guard let account = accounts.first(where: { $0.id == id }) else { return nil }

        // 使用Task来处理异步调用
        return try await Task {
            // 创建新实例以确保使用最新的GUID
            let appStoreService = AppStoreService(guid: deviceSeedAddress)

            let newAccount = try await appStoreService.login(
                email: account.email,
                password: account.password,
                authCode: ""
            )

            let countryCode = try appStoreService.storefrontService.countryCodeFromStoreFront(storeFront: newAccount.storeFront)

            // 转换ApplePackage.Account到AppStore.Account
            let updatedAccount = Account(
                email: account.email,
                password: account.password,
                countryCode: countryCode,
                storeResponse: .init(
                    email: newAccount.email,
                    passwordToken: newAccount.passwordToken,
                    directoryServicesID: newAccount.directoryServicesID,
                    name: newAccount.name,
                    storeFront: newAccount.storeFront,
                    password: newAccount.password
                )
            )

            if Thread.isMainThread {
                return save(email: account.email, password: account.password, account: updatedAccount)
            } else {
                var result: Account?
                DispatchQueue.main.asyncAndWait {
                    result = self.save(email: account.email, password: account.password, account: updatedAccount)
                }
                return result
            }
        }.result.get()
    }
}
