import Dynamic
import Foundation

class SystemInstaller {
    init() {}

    func installApp(from url: URL, appIdentifier: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.performInstallation(from: url, appIdentifier: appIdentifier)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private func performInstallation(from url: URL, appIdentifier: String) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(
                domain: "SystemInstallerError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "IPA file not found at specified path"]
            )
        }

        let workspace = Dynamic.LSApplicationWorkspace.defaultWorkspace

        let options: [String: Any] = [
            "CFBundleIdentifier": appIdentifier,
            "ApplicationType": "User",
        ]

        let retVal = workspace.installApplication(url, withOptions: options, error: nil).asInt ?? 1

        guard retVal == 0 else {
            throw NSError(
                domain: "SystemInstallerError",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Installation failed for unknown reason"]
            )
        }
    }
}
