//
//  AddDownloadView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import ApplePackage
import SwiftUI

struct AddDownloadView: View {
    @State var bundleID: String = ""
    @State var searchType: EntityType = .iPhone
    @State var selection: AppStore.Account.ID = .init()
    @State var obtainDownloadURL = false
    @State var hint = ""

    @FocusState var searchKeyFocused

    @StateObject var avm = AppStore.this
    @StateObject var dvm = Downloads.this

    @Environment(\.dismiss) var dismiss

    var account: AppStore.Account? {
        avm.accounts.first { $0.id == selection }
    }

    var body: some View {
        List {
            Section {
                TextField("Bundle ID", text: $bundleID)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
                    .focused($searchKeyFocused)
                    .onSubmit { startDownload() }
                Picker("EntityType", selection: $searchType) {
                    ForEach(EntityType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Bundle ID")
            } footer: {
                Text("Tell us the bundle ID of the app to initial a direct download. Useful to download apps that are no longer available in App Store.")
            }

            Section {
                if avm.demoMode {
                    Text("Demo Mode Redacted")
                        .redacted(reason: .placeholder)
                } else {
                    Picker("Account", selection: $selection) {
                        ForEach(avm.accounts) { account in
                            Text(account.email)
                                .id(account.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .onAppear { selection = avm.accounts.first?.id ?? .init() }
                }
            } header: {
                Text("Account")
            } footer: {
                Text("Select an account to download this app")
            }

            Section {
                Button(obtainDownloadURL ? "Communicating with Apple..." : "Request Download") {
                    startDownload()
                }
                .disabled(bundleID.isEmpty)
                .disabled(obtainDownloadURL)
                .disabled(account == nil)
            } footer: {
                if hint.isEmpty {
                    Text("Package can be installed later in download page.")
                } else {
                    Text(hint)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Direct Download")
    }

    func startDownload() {
        guard let account else { return }
        searchKeyFocused = false
        obtainDownloadURL = true
        Task.detached {
            do {
                // 创建App Store服务
                let appStoreService = AppStoreService(guid: avm.deviceSeedAddress)

                // 先构建一个临时账户用于查询
                let storefrontService = StorefrontService()
                let storefront = storefrontService.storeFronts[account.countryCode] ?? ""

                let tempAccount = Account(
                    email: account.email,
                    passwordToken: account.storeResponse.passwordToken,
                    directoryServicesID: account.storeResponse.directoryServicesID,
                    name: "",
                    storeFront: storefront,
                    password: account.password
                )

                // 使用新的lookup API查询应用
                let app = try await appStoreService.lookup(account: tempAccount, bundleID: bundleID)

                // 构造iTunesArchive
                let itunesApp = iTunesResponse.iTunesArchive(
                    from: app,
                    artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Purple128/v4/\(app.id)/100x100bb.jpg",
                    entityType: searchType
                )

                // 获取下载信息
                let downloadInfo = try await appStoreService.getDownloadInfo(account: tempAccount, app: app)

                // 添加下载请求
                let id = Downloads.this.add(request: .init(
                    account: .init(
                        email: tempAccount.email,
                        password: tempAccount.password,
                        countryCode: tempAccount.storeFront,
                        storeResponse: tempAccount
                    ),
                    package: .init(
                        identifier: itunesApp.identifier,
                        bundleIdentifier: itunesApp.bundleIdentifier,
                        name: itunesApp.name,
                        version: itunesApp.version
                    ),
                    url: downloadInfo.url,
                    md5: downloadInfo.md5,
                    sinfs: downloadInfo.sinfs,
                    metadata: [:]
                ))

                Downloads.this.resume(requestID: id)
            } catch {
                DispatchQueue.main.async {
                    obtainDownloadURL = false
                    if let appStoreError = error as? AppStoreError {
                        switch appStoreError {
                        case .licenseRequired:
                            hint = NSLocalizedString("License Not Found, please acquire license first.", comment: "")
                        case .passwordTokenExpired:
                            hint = NSLocalizedString("Password Token Expired, please re-authenticate within account page.", comment: "")
                        case .temporarilyUnavailable:
                            hint = NSLocalizedString("Temporarily Unavailable, please try again later.", comment: "")
                        default:
                            hint = NSLocalizedString("Unable to retrieve download url, please try again later.", comment: "") + "\n" + error.localizedDescription
                        }
                    } else {
                        hint = NSLocalizedString("Error: ", comment: "") + error.localizedDescription
                    }
                }
                return
            }
            DispatchQueue.main.async {
                hint = NSLocalizedString("Download Requested", comment: "")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        }
    }
}
