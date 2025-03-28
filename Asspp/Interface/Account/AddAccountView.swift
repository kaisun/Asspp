//
//  AddAccountView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import SwiftUI

struct AddAccountView: View {
    @StateObject var vm = AppStore.this
    @Environment(\.dismiss) var dismiss

    @State var email: String = ""
    @State var password: String = ""

    @State var codeRequired: Bool = false
    @State var code: String = ""

    @State var error: Error?
    @State var openProgress: Bool = false

    var body: some View {
        List {
            Section {
                TextField("Email (Apple ID)", text: $email)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                SecureField("Password", text: $password)
            } header: {
                Text("ID")
            } footer: {
                Text("We will store your account and password on disk without encryption. Please do not connect your device to untrusted hardware or use this app on a open system like macOS.")
            }
            if codeRequired {
                Section {
                    TextField("2FA Code (Optional)", text: $code)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .keyboardType(.numberPad)
                } header: {
                    Text("2FA Code")
                } footer: {
                    Text("Although 2FA code is marked as optional, that is because we dont know if you have it or just incorrect password, you should provide it if you have it enabled.\n\nhttps://support.apple.com/102606")
                }
                .transition(.opacity)
            }
            Section {
                if openProgress {
                    ForEach([UUID()], id: \.self) { _ in
                        ProgressView()
                    }
                } else {
                    Button("Authenticate") {
                        authenticate()
                    }
                    .disabled(openProgress)
                    .disabled(email.isEmpty || password.isEmpty)
                }
            } footer: {
                if let error {
                    Text(error.localizedDescription)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                        .transition(.opacity)
                }
            }
        }
        .animation(.spring, value: codeRequired)
        .listStyle(.insetGrouped)
        .navigationTitle("Add Account")
    }

    func authenticate() {
        openProgress = true
        Task {
            do {
                let appStoreService = AppStoreService(guid: UUID().uuidString)
                let account = try await appStoreService.login(
                    email: email,
                    password: password,
                    authCode: code.isEmpty ? "" : code
                )

                await MainActor.run {
                    vm.save(email: email, password: password, account: .init(
                        email: account.email,
                        password: account.password,
                        countryCode: account.storeFront,
                        storeResponse: account
                    ))
                    dismiss()
                    openProgress = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    codeRequired = true
                    openProgress = false
                }
            }
        }
    }
}
