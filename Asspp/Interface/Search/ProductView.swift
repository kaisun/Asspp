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
    let archive: AppPackage
    let region: String

    @StateObject var vm = AppStore.this
    @StateObject var dvm = Downloads.this

    var eligibleAccounts: [Account] {
        vm.accounts.filter { $0.countryCode == region }
    }

    var account: Account? {
        vm.accounts.first { $0.id == selection }
    }

    @State var selection: Account.ID = .init()
    @State var obtainDownloadURL = false
    @State var hint: String = ""
    @State var licenseHint: String = ""
    @State var acquiringLicense = false
    @State var licenseTask: Task<Void, Never>? = nil
    @State var downloadTask: Task<Void, Never>? = nil

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
                    Text("Please add account in account page.")
                }
            }
            pricing
            accountSelector
            buttons
            descriptionField
        }
        .onAppear {
            selection = eligibleAccounts.first?.id ?? .init()
        }
        .navigationTitle("Select Account")
    }

    var packageHeader: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                KFImage(URL(string: archive.artworkURL))
                    .antialiased(true)
                    .resizable()
                    .cornerRadius(8)
                    .frame(width: 50, height: 50, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(archive.name)
                    .bold()
                if let realaseNote = archive.releaseNotes {
                    Text(realaseNote)
                        .font(.system(.footnote, design: .rounded))
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Package")
        } footer: {
            Label("\(archive.bundleID) - \(archive.version) - \(archive.fileSize)", systemImage: archive.displaySupportedDevicesIcon)
        }
    }

    var pricing: some View {
        Section {
            Text(archive.formattedPrice)
                .font(.system(.body, design: .rounded))
            if archive.price.isZero {
                Button("Acquire License") {
                    licenseTask = Task {
                        await acquireLicense()
                        licenseTask = nil
                    }
                }
                .disabled(acquiringLicense)
                .disabled(account == nil)
            }
        } header: {
            Text("Pricing - \(archive.currency)")
        } footer: {
            if licenseHint.isEmpty {
                Text("Acquire license is not available for paid apps. If so, make purchase from the real App Store before download from here. If you already purchased this app, this operation will fail.")
            } else {
                Text(licenseHint)
                    .foregroundStyle(.red)
            }
        }
    }

    var accountSelector: some View {
        Section {
            Picker("Account", selection: $selection) {
                ForEach(eligibleAccounts) { account in
                    Text(account.email)
                        .id(account.id)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Account")
        } footer: {
            Text("You have searched this package with region \(region)")
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
                    downloadTask = Task {
                        await startDownload()
                        downloadTask = nil
                    }
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

    var descriptionField: some View {
        Section {
            Text(archive.description)
                .font(.system(.footnote, design: .rounded))
        } header: {
            Text("Description")
        }
    }

    nonisolated
    func startDownload() async {
        guard let account = await account else { return }
        await MainActor.run { obtainDownloadURL = true }
        let service = await vm.service

        do {
            let downloadInformation = try await service.getDownloadInfo(
                account: account.storeResponse,
                app: archive
            )

            print(downloadInformation)

            let downloadIdentifier = await Downloads.this.add(request: .init(
                account: account,
                package: archive,
                url: URL(string: downloadInformation.url)!,
                md5: downloadInformation.md5,
                sinfs: downloadInformation.sinfs
            ))

            Downloads.this.resume(requestID: downloadIdentifier)

            await MainActor.run {
                obtainDownloadURL = false
                hint = NSLocalizedString("Download Requested", comment: "")
            }
        } catch {
            await MainActor.run {
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
        }
    }

    nonisolated
    func acquireLicense() async {
        guard var account = await account else { return }
        await MainActor.run { acquiringLicense = true }

        if let newAccount = try? await AppStore.this.rotate(id: account.id) {
            // ignore failure, that's not critical
            account = newAccount
        }

        let service = await vm.service

        do {
            try await service.purchase(account: account.storeResponse, app: archive)

            await MainActor.run {
                acquiringLicense = false
                licenseHint = NSLocalizedString("Request Successes", comment: "")
            }
        } catch {
            await MainActor.run {
                acquiringLicense = false
                licenseHint = error.localizedDescription
            }
        }
    }
}
