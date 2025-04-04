@testable import ApplePackage
import Testing
import XCTest

final class AppStoreSearchTests: XCTestCase {
    func testSearchForMyLovelyFlowDown() async throws {
        let service = TestHelpers.service

        let searchResults = try await service.search(
            countryCode: "US",
            entityType: .macOS,
            term: "FlowDown",
            limit: 50
        )

        #expect(!searchResults.isEmpty)

        let targetBundleID = "wiki.qaq.flow"
        let foundApp = searchResults.first { app in
            app.bundleID == targetBundleID
        }

        #expect(foundApp != nil)
    }
}
