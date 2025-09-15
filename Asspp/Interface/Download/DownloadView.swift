//
//  DownloadView.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/11.
//

import SwiftUI

struct DownloadView: View {
    @StateObject var vm = Downloads.this

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Downloads")
        }
        .navigationViewStyle(.stack)
    }

    var content: some View {
        List {
            if vm.requests.isEmpty {
                Section("Packages") {
                    Text("No downloads yet.")
                }
            } else {
                Section("Packages (\(vm.requests.count)) - Active: \(vm.runningTaskCount)") {
                    packageList
                }
            }
        }
        .refreshable {
            for req in vm.requests {
                Task { await vm.checkAndUpdateDownloadStatus(for: req) }
            }
        }
        .toolbar {
            NavigationLink(destination: AddDownloadView()) {
                Image(systemName: "plus")
            }
        }
    }

    var packageList: some View {
        ForEach(vm.requests, id: \.id) { req in
            NavigationLink(destination: PackageView(request: req)) {
                VStack(spacing: 8) {
                    ArchivePreviewView(archive: req.package)
                    SimpleProgress(progress: req.runtime.percent)
                        .animation(.interactiveSpring, value: req.runtime.percent)
                    HStack {
                        Text(req.hint)
                        Spacer()
                        Text(req.creation.formatted())
                    }
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                }
            }
            .contextMenu {
                if vm.isCompleted(for: req) {
                    Button(role: .destructive) {
                        Task { await vm.delete(request: req) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } else {
                    switch req.runtime.status {
                    case .pending, .downloading:
                        Button {
                            Task { await vm.suspend(requestID: req.id) }
                        } label: {
                            Label("Pause", systemImage: "stop.fill")
                        }
                    case .paused:
                        Button {
                            Task { await vm.resume(requestID: req.id) }
                        } label: {
                            Label("Resume", systemImage: "play.fill")
                        }
                    default: Group {}
                    }
                    Button(role: .destructive) {
                        Task { await vm.delete(request: req) }
                    } label: {
                        Label("Cancel", systemImage: "trash")
                    }
                }
            }
        }
    }
}

extension Downloads.Request {
    var hint: String {
        if let error = runtime.error {
            return error
        }
        return switch runtime.status {
        case .pending:
            String(localized: "Pending...")
        case .downloading:
            [
                String(Int(runtime.percent * 100)) + "%",
                runtime.speed.isEmpty ? "" : runtime.speed + "/s",
            ]
            .compactMap(\.self)
            .joined(separator: " ")
        case .paused:
            String(localized: "Paused")
        case .completed:
            String(localized: "Completed")
        case .failed:
            String(localized: "Failed")
        }
    }
}
