import Foundation

public struct App: Codable {
    public let id: Int64
    public let bundleID: String
    public let name: String
    public let version: String
    public let price: Double

    enum CodingKeys: String, CodingKey {
        case id = "trackId"
        case bundleID = "bundleId"
        case name = "trackName"
        case version
        case price
    }

    public init(
        id: Int64,
        bundleID: String,
        name: String,
        version: String,
        price: Double
    ) {
        self.id = id
        self.bundleID = bundleID
        self.name = name
        self.version = version
        self.price = price
    }
}
