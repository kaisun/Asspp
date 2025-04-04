//
//  AppStore.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Combine
import Foundation

@MainActor
class AppStore: ObservableObject {
    static let this = AppStore()
    var cancellables: Set<AnyCancellable> = .init()

    @PublishedPersist(key: "DeviceSeedAddress", defaultValue: "")
    var deviceSeedAddress: String

    @PublishedPersist(key: "Accounts", defaultValue: [])
    var accounts: [Account]

    var service: AppStoreService {
        AppStoreService(guid: deviceSeedAddress)
    }

    private init() {
        if deviceSeedAddress.isEmpty { deviceSeedAddress = Self.createSeed() }
        assert(!deviceSeedAddress.isEmpty)
        deviceSeedAddress = deviceSeedAddress
    }

    func save(email: String, account: Account) {
        accounts = accounts
            .filter { $0.email.lowercased() != email.lowercased() }
            + [account]
    }

    func delete(id: Account.ID) {
        accounts = accounts.filter { $0.id != id }
    }
}
