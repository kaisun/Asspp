@testable import ApplePackage
import Testing
import XCTest

final class AppStoreAuthenticationTests: XCTestCase {
    func testLoginSuccess() async throws {
        let service = TestHelpers.service
        guard let testAccount = TestHelpers.loadTestAccount() else {
            throw NSError()
        }

        let email = testAccount.email
        let password = testAccount.password
        let code = testAccount.code

        print("[*] login begin \(email)")

        let account = try await service.login(email: email, password: password, authCode: code)
        #expect(!account.passwordToken.isEmpty)
        #expect(!account.name.isEmpty)
    }
}
