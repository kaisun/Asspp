//
//  SearchView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import ApplePackage
import Kingfisher
import SwiftUI

struct SearchView: View {
    @AppStorage("searchKey") var searchKey = ""
    @AppStorage("searchRegion") var searchRegion = "US"
    @FocusState var searchKeyFocused

    @State var task: Task<Void, Never>? = nil

    @State var searching = false
    @State var searchType = EntityType.iPhone
    @State var searchInput: String = ""
    @State var searchResult: (String, [AppPackage]) = ("", [])

    @StateObject var vm = AppStore.this

    var regionKeys: [String] {
        Array(vm.service.storefront.codeMap.keys).sorted()
    }

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
                    .onSubmit { submit() }
            } header: {
                Text("Metadata")
            }
            Section {
                Button(searching ? "Searching..." : "Search") { submit() }
                    .disabled(searchKey.isEmpty)
                    .disabled(searching)
            }
            Section {
                ForEach(searchResult.1) { item in
                    NavigationLink(destination: ProductView(archive: item, region: searchResult.0)) {
                        ArchivePreviewView(archive: item)
                    }
                    .transition(.opacity)
                }
            } header: {
                Text(searchInput)
            }
        }
        .animation(.spring, value: searchResult.0)
        .animation(.spring, value: searchResult.1)
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
                    Text("\(searchRegion) - \(vm.service.storefront.codeMap[searchRegion] ?? NSLocalizedString("Unknown", comment: ""))")
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
    }

    func buildPickView(for keys: [String]) -> some View {
        ForEach(keys, id: \.self) { key in
            Button("\(key) - \(vm.service.storefront.codeMap[key] ?? NSLocalizedString("Unknown", comment: ""))") {
                searchRegion = key
            }
        }
    }

    func submit() {
        task = Task {
            await search()
            task = nil
        }
    }

    nonisolated
    func search() async {
        await MainActor.run {
            searchKeyFocused = false
            searching = true
            searchInput = "\(searchRegion) - \(searchKey)" + " ..."
        }

        let region = await searchRegion
        let type = await searchType
        let keyword = await searchKey

        do {
            let apps = try await vm.service.search(
                countryCode: region,
                entityType: type,
                term: keyword,
                limit: 50
            )

            await MainActor.run {
                searching = false
                searchResult = (region, apps)
                searchInput = "\(region) - \(keyword)"
            }
        } catch {
            await MainActor.run {
                searching = false
                searchResult = ("", [])
                searchInput = "\(region) - \(keyword) \(error.localizedDescription)"
            }
        }
    }
}
