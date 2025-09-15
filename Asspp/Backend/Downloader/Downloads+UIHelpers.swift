//
//  Downloads+UIHelpers.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation
import SwiftUI

enum DownloadAction: Hashable {
    case suspend
    case resume
    case restart
    case delete
}

@MainActor
extension Downloads {
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
        switch request.runtime.status {
        case .pending, .downloading:
            [.suspend, .delete]
        case .paused:
            [.resume, .delete]
        case .failed:
            [.restart, .delete]
        case .completed:
            [.delete]
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
