import Foundation

public struct Account: Codable, Equatable, Hashable {
    public let email: String
    public let passwordToken: String
    public let directoryServicesID: String
    public let name: String
    public let storeFront: String
    public let password: String

    public init(
        email: String,
        passwordToken: String,
        directoryServicesID: String,
        name: String,
        storeFront: String,
        password: String
    ) {
        self.email = email
        self.passwordToken = passwordToken
        self.directoryServicesID = directoryServicesID
        self.name = name
        self.storeFront = storeFront
        self.password = password
    }
}
