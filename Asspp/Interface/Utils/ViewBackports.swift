//
//  ViewBackports.swift
//  Asspp
//
//  Created by luca on 19.09.2025.
//

import SwiftUI

extension View {
    @ViewBuilder
    func mediumAndLargeDetents() -> some View {
        if #available(iOS 16.0, *) {
            presentationDetents([.medium, .large])
        } else {
            self
        }
    }

    @ViewBuilder
    func neverMinimizeTab() -> some View {
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior(.never)
        } else {
            self
        }
    }

    @ViewBuilder
    func activateSearchWhenSearchTabSelected() -> some View {
        if #available(iOS 26.0, *) {
            tabViewSearchActivation(.searchTabSelection)
        } else {
            self
        }
    }

    @ViewBuilder
    func sidebarAdaptableTabView() -> some View {
        if #available(iOS 26.0, *) {
            tabViewStyle(.sidebarAdaptable)
        } else {
            self
        }
    }
}
