//
//  PackageView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Kingfisher
import SwiftUI

struct PackageView: View {
    let request: Downloads.Request
    var archive: AppStore.AppPackage {
        request.package
    }

    var url: URL { request.targetLocation }

    @Environment(\.dismiss) var dismiss
    @State var installer: Installer?
    @State var error: String = ""

    @StateObject var vm = AppStore.this
    @ObservedObject var downloads = Downloads.this

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    KFImage(URL(string: archive.software.artworkUrl))
                        .antialiased(true)
                        .resizable()
                        .cornerRadius(8)
                        .frame(width: 50, height: 50, alignment: .center)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(archive.software.name)
                        .bold()
                }
                .padding(.vertical, 4)
            } header: {
                Text("Package")
            } footer: {
                Text("\(archive.software.bundleID) - \(archive.software.version)")
            }

            if downloads.isCompleted(for: request) {
                Section {
                    Button("Install") {
                        Task {
                            do {
                                installer = try await Installer(archive: archive, path: url)
                            } catch {
                                self.error = error.localizedDescription
                            }
                        }
                    }
                    .sheet(item: $installer) {
                        installer?.destroy()
                        installer = nil
                    } content: {
                        InstallerView(installer: $0)
                    }

                    Button("Install via AirDrop") {
                        let newUrl = temporaryDirectory
                            .appendingPathComponent("\(archive.software.bundleID)-\(archive.software.version)")
                            .appendingPathExtension("ipa")
                        try? FileManager.default.removeItem(at: newUrl)
                        try? FileManager.default.copyItem(at: url, to: newUrl)
                        AirDrop(items: [newUrl])
                    }
                } header: {
                    Text("Control")
                } footer: {
                    if error.isEmpty {
                        Text("Direct install may have limitations that cannot be bypassed. Use AirDrop if possible on another device.")
                    } else {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    NavigationLink("Content Viewer") {
                        FileListView(packageURL: request.targetLocation)
                    }
                } header: {
                    Text("Analysis")
                } footer: {
                    Text("Developer options.")
                }
            } else {
                Section {
                    switch request.runtime.status {
                    case .pending:
                        Text("Download In Progress...")
                    case .downloading:
                        Text("Download In Progress...")
                    case .completed:
                        Group {}
                    case .failed:
                        Button("Restart Download") {
                            Task { await downloads.resume(requestID: request.id) }
                        }
                    }
                } header: {
                    Text("Incomplete Package")
                } footer: {
                    switch request.runtime.status {
                    case .pending:
                        Text("\(Int(request.runtime.percent * 100))%...")
                    case .downloading:
                        Text("\(Int(request.runtime.percent * 100))%...")
                    case .completed:
                        Group {}
                    case .failed:
                        Text("Download failed.")
                    }
                }
            }

            Section {
                if vm.demoMode {
                    Text("88888888888")
                        .redacted(reason: .placeholder)
                } else {
                    Text(request.account.account.email)
                }
                Text("\(request.account.account.store) - \(ApplePackage.Configuration.countryCode(for: request.account.account.store) ?? "-1")")
            } header: {
                Text("Account")
            } footer: {
                Text("This account is used to download this package. If you choose to AirDrop, your target device must sign in or previously signed in to this account and have at least one app installed.")
            }

            Section {
                Button("Delete") {
                    Task { await downloads.delete(request: request) }
                    dismiss()
                }
                .foregroundStyle(.red)
            } header: {
                Text("Danger Zone")
            } footer: {
                Text(url.path)
            }
        }
        .navigationTitle(request.package.software.name)
    }
}
