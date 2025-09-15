//
//  ProductView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Kingfisher
import SwiftUI

struct ProductView: View {
    @State var archive: AppStore.AppPackage
    let region: String

    @StateObject var vm = AppStore.this
    @StateObject var dvm = Downloads.this

    var eligibleAccounts: [AppStore.UserAccount] {
        vm.eligibleAccounts(for: region)
    }

    var account: AppStore.UserAccount? {
        vm.accounts.first { $0.id == selection }
    }

    @State var selection: AppStore.UserAccount.ID = .init()
    @State var obtainDownloadURL = false
    @State var licenseHint: String = ""
    @State var acquiringLicense = false
    @State var hint: String = ""

    var body: some View {
        List {
            packageHeader
            if account == nil {
                Section {
                    Text("No account available for this region.")
                        .foregroundStyle(.red)
                } header: {
                    Text("Error")
                } footer: {
                    Text("Please add an account in the Accounts page.")
                }
            }
            pricing
            accountSelector
            buttons
        }
        .onAppear {
            selection = eligibleAccounts.first?.id ?? .init()
        }
        .navigationTitle("Select Account")
    }

    var packageHeader: some View {
        Section {
            PackageDisplayView(archive: archive, style: .detail)
        } header: {
            Text("Package")
        } footer: {
            Label("\(archive.software.bundleID) - \(archive.software.version)", systemImage: "app")
        }
    }

    var pricing: some View {
        Section {
            Text("\(archive.software.formattedPrice)")
                .font(.system(.body, design: .rounded))
            if archive.software.price == 0 {
                Button("Acquire License") {
                    acquireLicense()
                }
                .disabled(acquiringLicense)
                .disabled(account == nil)
            }
        } header: {
            Text("Pricing")
        } footer: {
            if licenseHint.isEmpty {
                Text("Acquiring a license is not available for paid apps. Purchase from the App Store first, then download here. If you've already purchased it, this may fail.")
            } else {
                Text(licenseHint)
                    .foregroundStyle(.red)
            }
        }
    }

    var accountSelector: some View {
        Section {
            if vm.demoMode {
                Text("Demo Mode Redacted")
                    .redacted(reason: .placeholder)
            } else {
                Picker("Account", selection: $selection) {
                    ForEach(eligibleAccounts) { account in
                        Text(account.account.email)
                            .id(account.id)
                    }
                }
                .pickerStyle(.menu)
            }
        } header: {
            Text("Account")
        } footer: {
            Text(String(format: String(localized: "You have searched this package with region %@"), region))
        }
    }

    var buttons: some View {
        Section {
            if let req = dvm.downloadRequest(forArchive: archive) {
                NavigationLink(destination: PackageView(request: req)) {
                    Text("Show Download")
                }
            } else {
                Button(obtainDownloadURL ? "Communicating with Apple..." : "Request Download") {
                    startDownload()
                }
                .disabled(obtainDownloadURL)
                .disabled(account == nil)
            }
        } header: {
            Text("Download")
        } footer: {
            if hint.isEmpty {
                Text("Package can be installed later in download page.")
            } else {
                Text(hint)
                    .foregroundStyle(.red)
            }
        }
    }

    func startDownload() {
        guard let account else { return }
        obtainDownloadURL = true
        Task {
            do {
                var appleAccount = try account.toAppleAccount()
                let downloadOutput = try await ApplePackage.Download.download(
                    account: &appleAccount,
                    app: archive.software
                )
                archive.downloadOutput = downloadOutput
                let id = await Downloads.this.add(request: .init(
                    account: account,
                    package: archive,
                    downloadOutput: downloadOutput
                ))
                await Downloads.this.resume(requestID: id)
                await MainActor.run {
                    obtainDownloadURL = false
                    hint = String(localized: "Download Requested")
                }
            } catch {
                DispatchQueue.main.async {
                    obtainDownloadURL = false
                    hint = String(localized: "Unable to retrieve download url, please try again later.") + "\n" + error.localizedDescription
                }
            }
        }
    }

    func acquireLicense() {
        guard let account else { return }
        acquiringLicense = true
        Task {
            do {
                var appleAccount = try account.toAppleAccount()
                try await ApplePackage.Purchase.purchase(
                    account: &appleAccount,
                    app: archive.software
                )
                DispatchQueue.main.async {
                    acquiringLicense = false
                    licenseHint = String(localized: "Request Successes")
                }
            } catch {
                DispatchQueue.main.async {
                    acquiringLicense = false
                    licenseHint = error.localizedDescription
                }
            }
        }
    }
}

extension AppStore.AppPackage {
    var displaySupportedDevicesIcon: String {
        // Simplified, assuming iPhone for now
        "iphone"
    }
}
