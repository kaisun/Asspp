//
//  ProductHistoryView.swift
//  Asspp
//
//  Created by luca on 15.09.2025.
//

import ApplePackage
import SwiftUI

struct ProductHistoryView: View {
    @StateObject var vm: AppPackageArchive
    @State var showErrorAlert = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List(vm.versionIdentifiers, id: \.self) { key in
            if let aid = vm.accountIdentifier, let pkg = vm.package(for: key) {
                ProductVersionView(accountIdentifier: aid, package: pkg)
                    .transition(.opacity)
            }
        }
        .animation(.default, value: vm.versionIdentifiers)
        .animation(.default, value: vm.versionItems)
        .navigationTitle("Version History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if vm.loading {
                    ProgressView()
                } else {
                    Menu {
                        Button {
                            vm.populateNextVersionItems()
                        } label: {
                            Label("Load More", systemImage: "arrow.down.circle")
                        }
                        .disabled(vm.isVersionItemsFullyLoaded)
                        Divider()
                        Button(role: .destructive) {
                            vm.clearVersionItems()
                            vm.populateVersionIdentifiers {
                                await MainActor.run { vm.populateNextVersionItems() }
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .disabled(vm.loading) // just make sure
                }
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Oops"),
                message: Text(vm.error ?? String(localized: "Unknown Error")),
                dismissButton: .default(Text("OK"), action: {
                    if vm.shouldDismiss {
                        dismiss()
                    }
                })
            )
        }
        .onAppear {
            guard vm.versionItems.isEmpty else { return }
            vm.populateVersionIdentifiers {
                await MainActor.run { vm.populateNextVersionItems() }
            }
        }
        .onChange(of: vm.error) { newValue in
            showErrorAlert = newValue != nil
        }
    }
}
