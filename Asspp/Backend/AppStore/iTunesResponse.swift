import ApplePackage
import Foundation

enum iTunesResponse {
    struct iTunesArchive: Identifiable, Equatable, Codable, Hashable {
        let identifier: Int64
        let bundleIdentifier: String
        let name: String
        let version: String
        let price: Double?
        let formattedPrice: String?
        let currency: String?
        let artworkUrl512: String?
        let releaseNotes: String?
        let description: String?
        let supportedDevices: [String]?
        let entityType: EntityType?
        let byteCount: Int64?

        var id: String { bundleIdentifier }

        var byteCountDescription: String {
            if let bytes = byteCount, bytes > 0 {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useAll]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: bytes)
            }
            return ""
        }

        // 从新的 App 类型创建一个 iTunesArchive
        init(from app: App, artworkUrl: String? = nil, entityType: EntityType? = .iPhone) {
            identifier = app.id
            bundleIdentifier = app.bundleID
            name = app.name
            version = app.version
            price = app.price
            formattedPrice = app.price > 0 ? String(format: "$%.2f", app.price) : "免费"
            currency = "USD" // 默认值
            artworkUrl512 = artworkUrl
            releaseNotes = nil
            description = nil
            supportedDevices = []
            self.entityType = entityType
            byteCount = 0
        }

        // 手动构造函数
        init(
            identifier: Int64,
            bundleIdentifier: String,
            name: String,
            version: String,
            price: Double? = nil,
            formattedPrice: String? = nil,
            currency: String? = nil,
            artworkUrl512: String? = nil,
            releaseNotes: String? = nil,
            description: String? = nil,
            supportedDevices: [String]? = nil,
            entityType: EntityType? = nil,
            byteCount: Int64? = nil
        ) {
            self.identifier = identifier
            self.bundleIdentifier = bundleIdentifier
            self.name = name
            self.version = version
            self.price = price
            self.formattedPrice = formattedPrice
            self.currency = currency
            self.artworkUrl512 = artworkUrl512
            self.releaseNotes = releaseNotes
            self.description = description
            self.supportedDevices = supportedDevices
            self.entityType = entityType
            self.byteCount = byteCount
        }
    }
}

// 添加扩展用于设备图标显示
extension iTunesResponse.iTunesArchive {
    var displaySupportedDevicesIcon: String {
        var supports_iPhone = false
        var supports_iPad = false
        for device in supportedDevices ?? [] {
            if device.lowercased().contains("iphone") {
                supports_iPhone = true
            }
            if device.lowercased().contains("ipad") {
                supports_iPad = true
            }
        }
        if supports_iPhone, supports_iPad {
            return "ipad.and.iphone"
        } else if supports_iPhone {
            return "iphone"
        } else if supports_iPad {
            return "ipad"
        } else {
            return "questionmark"
        }
    }
}
