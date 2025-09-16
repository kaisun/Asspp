//
//  MainView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import SwiftUI

struct MainView: View {
    @StateObject var dvm = Downloads.this

    var body: some View {
        TabView {
            WelcomeView()
                .tabItem { Label("Home", systemImage: "house") }
            AccountView()
                .tabItem { Label("Accounts", systemImage: "person") }
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
            DownloadView()
                .tabItem {
                    Label("Downloads", systemImage: "arrow.down.circle")
                        .badge(dvm.runningTaskCount)
                }
            SettingView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

@available(iOS 26.0, *)
struct NewMainView: View {
    @StateObject var dvm = Downloads.this

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") { WelcomeView() }
            Tab("Accounts", systemImage: "person") { AccountView() }
            Tab("Downloads", systemImage: "arrow.down.circle") { DownloadView() }
                .badge(dvm.runningTaskCount)
            Tab("Settings", systemImage: "gear") { SettingView() }

            Tab(role: .search) {
                SearchView()
            }
        }
        .tabBarMinimizeBehavior(.never)
        .tabViewSearchActivation(.searchTabSelection)
        .tabViewStyle(.sidebarAdaptable)
    }
}
