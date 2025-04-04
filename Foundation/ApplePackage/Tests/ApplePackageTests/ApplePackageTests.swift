@testable import ApplePackage
import Foundation
import Testing

public struct TestAccount: Codable {
    public let email: String
    public let password: String
    public let code: String

    public init(email: String, password: String, code: String) {
        self.email = email
        self.password = password
        self.code = code
    }
}

public enum TestHelpers {
    public static let service = AppStoreService(guid: "0624A65AF7E5")

    public static func loadTestAccount() -> TestAccount? {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        let testFilePath = homeDirectory.appendingPathComponent(".test/login.json")

        do {
            let data = try Data(contentsOf: testFilePath)
            let decoder = JSONDecoder()
            return try decoder.decode(TestAccount.self, from: data)
        } catch {
            fatalError("unable to load test account: \(error)")
        }
    }
}
