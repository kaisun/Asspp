import AnyCodable
import Foundation

public class AppStoreService {
    public let guid: String

    public init(guid: String) {
        self.guid = guid
    }

    public nonisolated
    let zipUtility: ZipUtility = .shared

    public nonisolated
    let storefront: StorefrontService = .shared
}
