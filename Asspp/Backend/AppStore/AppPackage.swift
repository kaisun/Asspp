//
//  AppPackage.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Foundation

extension AppStore {
    struct AppPackage: Codable, Identifiable, Hashable {
        var id: String { software.bundleID }

        let software: ApplePackage.Software
        var downloadOutput: ApplePackage.DownloadOutput?

        init(software: ApplePackage.Software) {
            self.software = software
        }

        static func == (lhs: AppPackage, rhs: AppPackage) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
