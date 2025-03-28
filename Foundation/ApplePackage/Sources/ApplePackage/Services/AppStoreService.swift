import AnyCodable
import Foundation

public class AppStoreService {
    let zipUtility: ZipProtocol
    let storefrontService: StorefrontService
    let guid: String

    public init(
        guid: String,
        zipUtility: ZipProtocol = ZipUtility.shared
    ) {
        self.guid = guid
        self.zipUtility = zipUtility
        storefrontService = StorefrontService()
    }
}
