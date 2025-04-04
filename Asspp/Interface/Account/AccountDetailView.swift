//
//  AccountDetailView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import SwiftUI

struct AccountDetailView: View {
    let account: Account

    @StateObject var vm = AppStore.this
    @Environment(\.dismiss) var dismiss

    @State var rotating = false
    @State var rotatingHint = ""

    @State var task: Task<Void, Never>?

    var body: some View {
        List {
            Section {
                Text(account.email)
                    .onTapGesture { UIPasteboard.general.string = account.email }
            } header: {
                Text("ID")
            } footer: {
                Text("This email is used to sign in to Apple services.")
            }
            Section {
                Text("\(account.countryCode) - \(StorefrontService.shared.codeMap[account.countryCode] ?? NSLocalizedString("Unknown", comment: ""))")
                    .onTapGesture { UIPasteboard.general.string = account.email }
            } header: {
                Text("Country Code")
            } footer: {
                Text("App Store requires this country code to identify your package region.")
            }
            Section {
                Text(account.storeResponse.directoryServicesID)
                    .font(.system(.body, design: .monospaced))
                    .onTapGesture { UIPasteboard.general.string = account.email }
                Text(AppStore.this.deviceSeedAddress)
                    .font(.system(.body, design: .monospaced))
                    .onTapGesture { UIPasteboard.general.string = account.email }
            } header: {
                Text("Services ID")
            } footer: {
                Text("ID combined with a random seed generated on this device can download package from App Store.")
            }
            Section {
                SecureField(text: .constant(account.storeResponse.passwordToken)) {
                    Text("Password Token")
                }
                if rotating {
                    Button("Rotating...") {}
                        .disabled(true)
                } else {
                    Button("Rotate Token") {
                        task = Task {
                            await rotate()
                            task = nil
                        }
                    }
                }
            } header: {
                Text("Password Token")
            } footer: {
                if rotatingHint.isEmpty {
                    Text("If you failed to acquire license for product, rotate the password token may help. This will use the initial password to authenticate with App Store again.")
                } else {
                    Text(rotatingHint)
                        .foregroundStyle(.red)
                }
            }
            Section {
                Button("Delete") {
                    vm.delete(id: account.id)
                    dismiss()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Detail")
    }

    nonisolated
    func rotate() async {
        await MainActor.run { rotating = true }
        do {
            try await vm.rotate(id: account.id)
            await MainActor.run {
                rotating = false
                rotatingHint = NSLocalizedString("Success", comment: "")
            }
        } catch {
            await MainActor.run {
                rotating = false
                rotatingHint = error.localizedDescription
            }
        }
    }
}
