//
//  AccountView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Combine
import SwiftUI

struct AccountView: View {
    @StateObject var vm = AppStore.this
    @State var addAccount = false

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Account")
                .toolbar {
                    ToolbarItem {
                        NavigationLink(
                            destination: AddAccountView(),
                            isActive: $addAccount,
                            label: {
                                Button {
                                    addAccount.toggle()
                                } label: {
                                    Label("Add Account", systemImage: "plus")
                                }
                            }
                        )
                    }
                }
        }
        .navigationViewStyle(.stack)
    }

    var content: some View {
        List {
            Section {
                ForEach(vm.accounts) { account in
                    NavigationLink(destination: AccountDetailView(account: account)) {
                        Text(account.email)
                    }
                }
                if vm.accounts.isEmpty {
                    Text("Sorry, nothing here.")
                }
            } header: {
                Text("IDs")
            } footer: {
                Text("Your account is not encrypted on disk.")
            }
        }
    }
}
