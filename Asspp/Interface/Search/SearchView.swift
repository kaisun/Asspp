//
//  SearchView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Kingfisher
import SwiftUI

enum EntityType: String, CaseIterable, Codable {
    case iPhone
    case iPad
    case macOS
    case watchOS
    case tvOS
}

struct SearchView: View {
    @AppStorage("searchKey") var searchKey = ""
    @AppStorage("searchRegion") var searchRegion = "US"
    @FocusState var searchKeyFocused
    @State var searchType = EntityType.iPhone

    @State var searching = false
    let regionKeys = Array(ApplePackage.storeFrontCodeMap.keys.sorted())

    @State var searchInput: String = ""
    @State var searchResult: [iTunesResponse.iTunesArchive] = []

    @StateObject var vm = AppStore.this

    var possibleReigon: Set<String> {
        Set(vm.accounts.map(\.countryCode))
    }

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Search")
        }
        .navigationViewStyle(.stack)
    }

    var content: some View {
        List {
            Section {
                Picker("Type", selection: $searchType) {
                    ForEach(EntityType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)

                buildRegionView()

                TextField("Keyword", text: $searchKey)
                    .focused($searchKeyFocused)
                    .onSubmit { search() }
            } header: {
                Text("Metadata")
            }
            Section {
                Button(searching ? "Searching..." : "Search") { search() }
                    .disabled(searchKey.isEmpty)
                    .disabled(searching)
            }
            Section {
                ForEach(searchResult) { item in
                    NavigationLink(destination: ProductView(archive: item, region: searchRegion)) {
                        ArchivePreviewView(archive: item)
                    }
                    .transition(.opacity)
                }
            } header: {
                Text(searchInput)
            }
        }
        .animation(.spring, value: searchResult)
    }

    func buildRegionView() -> some View {
        HStack {
            Text("Region")
            Spacer()
            Menu {
                Section("Account") {
                    buildPickView(for: regionKeys.filter { possibleReigon.contains($0) })
                }
                Menu("All Region") {
                    buildPickView(for: regionKeys)
                }
            } label: {
                HStack {
                    Text("\(searchRegion) - \(ApplePackage.storeFrontCodeMap[searchRegion] ?? NSLocalizedString("Unknown", comment: ""))")
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
    }

    func buildPickView(for keys: [String]) -> some View {
        ForEach(keys, id: \.self) { key in
            Button("\(key) - \(ApplePackage.storeFrontCodeMap[key] ?? NSLocalizedString("Unknown", comment: ""))") {
                searchRegion = key
            }
        }
    }

    func search() {
        searchKeyFocused = false
        searching = true
        searchInput = "\(searchRegion) - \(searchKey)" + " ..."
        Task {
            // 创建服务实例
            let appStoreService = AppStoreService(guid: vm.deviceSeedAddress)

            do {
                // 构建一个临时账户用于搜索
                let storefront = ApplePackage.storeFrontCodeMap[searchRegion] ?? ""

                let tempAccount = Account(
                    email: "",
                    passwordToken: "",
                    directoryServicesID: "",
                    name: "",
                    storeFront: storefront,
                    password: ""
                )

                // 使用搜索服务
                let apps = try await appStoreService.search(
                    account: tempAccount,
                    term: searchKey,
                    limit: 32
                )

                // 转换为 iTunesResponse.iTunesArchive
                let results = apps.map { app -> iTunesResponse.iTunesArchive in
                    // 构建缩略图URL
                    let artworkUrl = "https://is1-ssl.mzstatic.com/image/thumb/Purple128/v4/\(String(app.id))/100x100bb.jpg"

                    return iTunesResponse.iTunesArchive(
                        from: app,
                        artworkUrl: artworkUrl,
                        entityType: searchType
                    )
                }

                DispatchQueue.main.async {
                    searching = false
                    searchResult = results
                    searchInput = "\(searchRegion) - \(searchKey)"
                }
            } catch {
                DispatchQueue.main.async {
                    searching = false
                    searchResult = []
                    searchInput = "\(searchRegion) - \(searchKey) (错误: \(error.localizedDescription))"
                }
            }
        }
    }
}
