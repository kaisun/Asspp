//
//  Downloads+UIHelpers.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation
import SwiftUI

// MARK: - Download Action Protocol

protocol DownloadActionHandler {
    func performDownloadAction(for request: Downloads.Request, action: DownloadAction) async
    func getAvailableActions(for request: Downloads.Request) -> [DownloadAction]
    func getActionLabel(for action: DownloadAction) -> (title: String, systemImage: String, isDestructive: Bool)
}

// MARK: - Download Action Types

enum DownloadAction: Hashable {
    case suspend
    case resume
    case restart
    case delete
}

// MARK: - UI Helper Extension

extension Downloads: @MainActor DownloadActionHandler {
    // MARK: - UI Helper Methods

    func performDownloadAction(for request: Request, action: DownloadAction) async {
        switch action {
        case .suspend:
            await suspend(requestID: request.id)
        case .resume:
            await resume(requestID: request.id)
        case .restart:
            await restart(requestID: request.id)
        case .delete:
            await delete(request: request)
        }
    }

    func getAvailableActions(for request: Request) -> [DownloadAction] {
        // Early return for completed requests
        guard !isCompleted(for: request) else {
            return [.delete]
        }

        // Switch on status with single responsibility
        switch request.runtime.status {
        case .pending, .downloading:
            return [.suspend, .delete]
        case .paused:
            return [.resume, .delete]
        case .failed:
            return [.restart, .delete]
        case .completed:
            return [.delete]
        }
    }

    func getActionLabel(for action: DownloadAction) -> (title: String, systemImage: String, isDestructive: Bool) {
        switch action {
        case .suspend:
            (String(localized: "Pause"), "stop.fill", false)
        case .resume:
            (String(localized: "Resume"), "play.fill", false)
        case .restart:
            (String(localized: "Restart Download"), "arrow.clockwise", false)
        case .delete:
            (String(localized: "Delete"), "trash", true)
        }
    }
}
