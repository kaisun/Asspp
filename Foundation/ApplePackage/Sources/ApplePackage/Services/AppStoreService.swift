import AnyCodable
import Foundation

public class AppStoreService {
    public let zipUtility: ZipProtocol
    public let storefrontService: StorefrontService
    public let guid: String

    public init(
        guid: String,
        zipUtility: ZipProtocol = ZipUtility.shared
    ) {
        self.guid = guid
        self.zipUtility = zipUtility
        storefrontService = StorefrontService()
    }
}
