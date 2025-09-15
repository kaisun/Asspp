//
//  Downloads+Status.swift
//  Asspp
//
//  Created by 秋星桥 on 2024/7/13.
//

import Foundation

extension Downloads {
    func checkAndUpdateDownloadStatus(for request: Downloads.Request) async {
        let fileURL = request.targetLocation

        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            await updateRequestStatus(request.id, status: .failed, percent: 0, error: nil)
            return
        }

        do {
            let fileValidation = try await validateDownloadedFile(at: fileURL, expectedMD5: request.md5)
            switch fileValidation {
            case .valid:
                await updateRequestStatus(request.id, status: .completed, percent: 1.0, error: nil)
            case .invalid:
                await updateRequestStatus(request.id, status: .failed, percent: 0, error: String(localized: "The downloaded file appears to be corrupted or incomplete."))
                try? FileManager.default.removeItem(at: fileURL)
            case .unableToVerify:
                await updateRequestStatus(request.id, status: .failed, percent: 0, error: String(localized: "Unable to verify the integrity of the downloaded file."))
            case .empty:
                await updateRequestStatus(request.id, status: .failed, percent: 0, error: String(localized: "The downloaded file is empty."))
                try? FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            await updateRequestStatus(request.id, status: .failed, percent: 0, error: String(localized: "Unable to access the file: \(error.localizedDescription)"))
        }
    }

    private func validateDownloadedFile(at url: URL, expectedMD5 _: String?) async throws -> FileValidationResult {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        guard fileSize >= 0 else {
            throw NSError(domain: "FileValidation", code: -1, userInfo: [NSLocalizedDescriptionKey: String(localized: "The file size is invalid.")])
        }

        if fileSize == 0 {
            return .empty
        }

        // TODO: Implement MD5 validation
        return .valid
    }

    func updateRequestStatus(_ requestID: Downloads.Request.ID, status: Runtime.Status, percent: Double, error: String?) async {
        guard let index = requests.firstIndex(where: { $0.id == requestID }) else { return }
        requests[index].runtime.status = status
        requests[index].runtime.percent = percent
        requests[index].runtime.error = error
    }

    func isCompleted(for request: Request) -> Bool {
        request.runtime.status == .completed
    }
}

private enum FileValidationResult {
    case valid
    case invalid
    case unableToVerify
    case empty
}
