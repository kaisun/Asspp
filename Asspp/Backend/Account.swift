//
//  Account.swift
//  Asspp
//
//  Created by 秋星桥 on 4/4/25.
//

import ApplePackage
import Foundation

struct Account: Codable, Identifiable, Hashable {
    var id: String { email }

    var email: String
    var password: String
    var countryCode: String
    var storeResponse: ApplePackage.Account
}
