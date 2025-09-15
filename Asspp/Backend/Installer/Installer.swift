//
//  Installer.swift
//  AppInstaller
//
//  Created by 秋星桥 on 2024/7/10.
//

import ApplePackage
import Logging
import UIKit
import Vapor

class Installer: Identifiable, ObservableObject, @unchecked Sendable {
    let id: UUID
    let app: Application
    let archive: AppStore.AppPackage
    let port = Int.random(in: 4000 ... 8000)

    enum Status {
        case ready
        case sendingManifest
        case sendingPayload
        case completed(Result<Void, Error>)
        case broken(Error)
    }

    @MainActor
    @Published var status: Status = .ready

    init(archive: AppStore.AppPackage, path packagePath: URL) async throws {
        let id: UUID = .init()
        self.id = id
        self.archive = archive
        app = try await Self.setupApp(port: port)
        logger.info("Installer app setup completed for ID: \(id)")

        app.get("*") { [weak self] req in
            guard let self else { return Response(status: .badGateway) }

            switch req.url.path {
            case "/ping":
                return Response(status: .ok, body: .init(string: "pong"))
            case "/", "/index.html":
                return Response(status: .ok, version: req.version, headers: [
                    "Content-Type": "text/html",
                ], body: .init(string: indexHtml))
            case plistEndpoint.path:
                await MainActor.run { self.status = .sendingManifest }
                logger.info("sending manifest for installer id: \(self.id)")
                return Response(status: .ok, version: req.version, headers: [
                    "Content-Type": "text/xml",
                ], body: .init(data: installManifestData))
            case displayImageSmallEndpoint.path:
                await MainActor.run { self.status = .sendingManifest }
                logger.info("sending small display image for installer id: \(self.id)")
                return Response(status: .ok, version: req.version, headers: [
                    "Content-Type": "image/png",
                ], body: .init(data: displayImageSmallData))
            case displayImageLargeEndpoint.path:
                await MainActor.run { self.status = .sendingManifest }
                logger.info("sending large display image for installer id: \(self.id)")
                return Response(status: .ok, version: req.version, headers: [
                    "Content-Type": "image/png",
                ], body: .init(data: displayImageLargeData))
            case payloadEndpoint.path:
                await MainActor.run { self.status = .sendingPayload }
                logger.info("starting payload transfer for installer id: \(self.id)")

                let result = try await req.fileio.asyncStreamFile(
                    at: packagePath.path,
                    chunkSize: 64 * 1024,
                ) { result in
                    await MainActor.run {
                        self.status = .completed(result)
                        if case .success = result {
                            logger.info("payload transfer completed for installer id: \(self.id)")
                        } else {
                            logger.error("payload transfer failed for installer id: \(self.id)")
                        }
                    }
                }
                return result
            default:
                // 404
                logger.warning("unknown request path: \(req.url.path) for installer id: \(self.id)")
                return Response(status: .notFound)
            }
        }

        try app.server.start()
        logger.info("installer init at port \(port) for sni \(Self.sni)")
    }

    deinit {
        destroy()
    }

    func destroy() {
        guard !app.didShutdown else { return }
        logger.info("installer destroy")
        Task.detached {
            await self.app.server.shutdown()
            try await self.app.asyncShutdown()
            withExtendedLifetime(self) { _ in }
            withExtendedLifetime(self.app) { _ in }
        }
    }
}
