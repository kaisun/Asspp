import Foundation

public struct AppPackage: Codable, Identifiable, Equatable, Hashable {
    public let id: Int64
    public let bundleID: String
    public let name: String
    public let version: String
    public let price: Double
    public let formattedPrice: String
    public let releaseNotes: String?
    public let sellerName: String
    public let minimumOSVersion: String
    public let releaseDate: String
    public let description: String
    public let supportedDevices: [String]
    public let languageCodes: [String]
    public let fileSize: String
    public let currency: String
    public let artworkURL: String
    public let artworkPreviewURL: String
    public let genres: [String]
    public let primaryGenre: String

    enum CodingKeys: String, CodingKey {
        case id = "trackId"
        case bundleID = "bundleId"
        case name = "trackName"
        case version
        case price
        case formattedPrice
        case releaseNotes
        case sellerName
        case minimumOSVersion = "minimumOsVersion"
        case releaseDate
        case description
        case supportedDevices
        case languageCodes = "languageCodesISO2A"
        case fileSize = "fileSizeBytes"
        case currency
        case artworkURL = "artworkUrl512"
        case artworkPreviewURL = "artworkUrl100"
        case genres
        case primaryGenre = "primaryGenreName"
    }

    public init(
        id: Int64,
        bundleID: String,
        name: String,
        version: String,
        price: Double,
        formattedPrice: String,
        releaseNotes: String?,
        sellerName: String,
        minimumOSVersion: String,
        releaseDate: String,
        description: String,
        supportedDevices: [String],
        languageCodes: [String],
        fileSize: String,
        currency: String,
        artworkURL: String,
        artworkPreviewURL: String,
        genres: [String],
        primaryGenre: String
    ) {
        self.id = id
        self.bundleID = bundleID
        self.name = name
        self.version = version
        self.price = price
        self.formattedPrice = formattedPrice
        self.releaseNotes = releaseNotes
        self.sellerName = sellerName
        self.minimumOSVersion = minimumOSVersion
        self.releaseDate = releaseDate
        self.description = description
        self.supportedDevices = supportedDevices
        self.languageCodes = languageCodes
        self.fileSize = fileSize
        self.currency = currency
        self.artworkURL = artworkURL
        self.artworkPreviewURL = artworkPreviewURL
        self.genres = genres
        self.primaryGenre = primaryGenre
    }
}

/*
 {
   "results": [
     {
       "primaryGenreName": "Utilities",
       "artworkUrl100": "https:\/\/is1-ssl.mzstatic.com\/image\/thumb\/Purple211\/v4\/4c\/36\/6b\/4c366bd0-bbc5-3928-6ea2-53ac1f2d9ac0\/AppIcon-0-0-1x_U007epad-0-1-85-220.jpeg\/100x100bb.jpg",
       "currency": "USD",
       "artworkUrl512": "https:\/\/is1-ssl.mzstatic.com\/image\/thumb\/Purple211\/v4\/4c\/36\/6b\/4c366bd0-bbc5-3928-6ea2-53ac1f2d9ac0\/AppIcon-0-0-1x_U007epad-0-1-85-220.jpeg\/512x512bb.jpg",
       "ipadScreenshotUrls": [
       ],
       "fileSizeBytes": "69398528",
       "genres": [
         "Utilities",
         "Reference"
       ],
       "languageCodesISO2A": [
         "EN",
         "ZH"
       ],
       "artworkUrl60": "https:\/\/is1-ssl.mzstatic.com\/image\/thumb\/Purple211\/v4\/4c\/36\/6b\/4c366bd0-bbc5-3928-6ea2-53ac1f2d9ac0\/AppIcon-0-0-1x_U007epad-0-1-85-220.jpeg\/60x60bb.jpg",
       "supportedDevices": [
         "MacDesktop-MacDesktop",
         "iPhone5s-iPhone5s",
         "iPadAir-iPadAir",
         "iPadAirCellular-iPadAirCellular",
         "iPadMiniRetina-iPadMiniRetina",
         "iPadMiniRetinaCellular-iPadMiniRetinaCellular",
         "iPhone6-iPhone6",
         "iPhone6Plus-iPhone6Plus",
         "iPadAir2-iPadAir2",
         "iPadAir2Cellular-iPadAir2Cellular",
         "iPadMini3-iPadMini3",
         "iPadMini3Cellular-iPadMini3Cellular",
         "iPodTouchSixthGen-iPodTouchSixthGen",
         "iPhone6s-iPhone6s",
         "iPhone6sPlus-iPhone6sPlus",
         "iPadMini4-iPadMini4",
         "iPadMini4Cellular-iPadMini4Cellular",
         "iPadPro-iPadPro",
         "iPadProCellular-iPadProCellular",
         "iPadPro97-iPadPro97",
         "iPadPro97Cellular-iPadPro97Cellular",
         "iPhoneSE-iPhoneSE",
         "iPhone7-iPhone7",
         "iPhone7Plus-iPhone7Plus",
         "iPad611-iPad611",
         "iPad612-iPad612",
         "iPad71-iPad71",
         "iPad72-iPad72",
         "iPad73-iPad73",
         "iPad74-iPad74",
         "iPhone8-iPhone8",
         "iPhone8Plus-iPhone8Plus",
         "iPhoneX-iPhoneX",
         "iPad75-iPad75",
         "iPad76-iPad76",
         "iPhoneXS-iPhoneXS",
         "iPhoneXSMax-iPhoneXSMax",
         "iPhoneXR-iPhoneXR",
         "iPad812-iPad812",
         "iPad834-iPad834",
         "iPad856-iPad856",
         "iPad878-iPad878",
         "iPadMini5-iPadMini5",
         "iPadMini5Cellular-iPadMini5Cellular",
         "iPadAir3-iPadAir3",
         "iPadAir3Cellular-iPadAir3Cellular",
         "iPodTouchSeventhGen-iPodTouchSeventhGen",
         "iPhone11-iPhone11",
         "iPhone11Pro-iPhone11Pro",
         "iPadSeventhGen-iPadSeventhGen",
         "iPadSeventhGenCellular-iPadSeventhGenCellular",
         "iPhone11ProMax-iPhone11ProMax",
         "iPhoneSESecondGen-iPhoneSESecondGen",
         "iPadProSecondGen-iPadProSecondGen",
         "iPadProSecondGenCellular-iPadProSecondGenCellular",
         "iPadProFourthGen-iPadProFourthGen",
         "iPadProFourthGenCellular-iPadProFourthGenCellular",
         "iPhone12Mini-iPhone12Mini",
         "iPhone12-iPhone12",
         "iPhone12Pro-iPhone12Pro",
         "iPhone12ProMax-iPhone12ProMax",
         "iPadAir4-iPadAir4",
         "iPadAir4Cellular-iPadAir4Cellular",
         "iPadEighthGen-iPadEighthGen",
         "iPadEighthGenCellular-iPadEighthGenCellular",
         "iPadProThirdGen-iPadProThirdGen",
         "iPadProThirdGenCellular-iPadProThirdGenCellular",
         "iPadProFifthGen-iPadProFifthGen",
         "iPadProFifthGenCellular-iPadProFifthGenCellular",
         "iPhone13Pro-iPhone13Pro",
         "iPhone13ProMax-iPhone13ProMax",
         "iPhone13Mini-iPhone13Mini",
         "iPhone13-iPhone13",
         "iPadMiniSixthGen-iPadMiniSixthGen",
         "iPadMiniSixthGenCellular-iPadMiniSixthGenCellular",
         "iPadNinthGen-iPadNinthGen",
         "iPadNinthGenCellular-iPadNinthGenCellular",
         "iPhoneSEThirdGen-iPhoneSEThirdGen",
         "iPadAirFifthGen-iPadAirFifthGen",
         "iPadAirFifthGenCellular-iPadAirFifthGenCellular",
         "iPhone14-iPhone14",
         "iPhone14Plus-iPhone14Plus",
         "iPhone14Pro-iPhone14Pro",
         "iPhone14ProMax-iPhone14ProMax",
         "iPadTenthGen-iPadTenthGen",
         "iPadTenthGenCellular-iPadTenthGenCellular",
         "iPadPro11FourthGen-iPadPro11FourthGen",
         "iPadPro11FourthGenCellular-iPadPro11FourthGenCellular",
         "iPadProSixthGen-iPadProSixthGen",
         "iPadProSixthGenCellular-iPadProSixthGenCellular",
         "iPhone15-iPhone15",
         "iPhone15Plus-iPhone15Plus",
         "iPhone15Pro-iPhone15Pro",
         "iPhone15ProMax-iPhone15ProMax",
         "iPadAir11M2-iPadAir11M2",
         "iPadAir11M2Cellular-iPadAir11M2Cellular",
         "iPadAir13M2-iPadAir13M2",
         "iPadAir13M2Cellular-iPadAir13M2Cellular",
         "iPadPro11M4-iPadPro11M4",
         "iPadPro11M4Cellular-iPadPro11M4Cellular",
         "iPadPro13M4-iPadPro13M4",
         "iPadPro13M4Cellular-iPadPro13M4Cellular",
         "iPhone16-iPhone16",
         "iPhone16Plus-iPhone16Plus",
         "iPhone16Pro-iPhone16Pro",
         "iPhone16ProMax-iPhone16ProMax",
         "iPadMiniA17Pro-iPadMiniA17Pro",
         "iPadMiniA17ProCellular-iPadMiniA17ProCellular",
         "iPhone16e-iPhone16e",
         "iPadA16-iPadA16",
         "iPadA16Cellular-iPadA16Cellular",
         "iPadAir11M3-iPadAir11M3",
         "iPadAir11M3Cellular-iPadAir11M3Cellular",
         "iPadAir13M3-iPadAir13M3",
         "iPadAir13M3Cellular-iPadAir13M3Cellular"
       ],
       "bundleId": "wiki.qaq.flow",
       "description": "FlowDown is a fast and smooth client app designed to enhance your experience with AI\/LLM.\n\nVisit our website for more information: https:\/\/flowdown.ai\/. A comprehensive documentation guide is provided there.\n\n## Features\n\n- **Lightweight and Efficient**: Sleek design for seamless performance\n- **Markdown Support**: Richly formatted text in responses\n- **Universal Compatibility**: Works with all OpenAI-compatible service providers\n- **Blazing Fast Text Rendering**: Ensures a smooth user experience\n- **Automated Chat Titles**: Organizes conversations and boosts productivity\n- **Privacy by Design**: We don't collect your data, and offline models are available\n\nAfter downloading this app, you'll find a free model included to get started right away. Simply click \"fetch\" with no hidden fees involved.\n\n*AI-generated content may contain misleading information. We are not responsible for that, so please use it with caution.*\n\n*Running offline local models requires Apple Silicon devices with a reasonable memory.*\n\n© 2025 FlowDown Team. All Rights Reserved.",
       "version": "1.4",
       "trackViewUrl": "https:\/\/apps.apple.com\/us\/app\/flowdown-open-fast-ai\/id6740553198?uo=4",
       "artistViewUrl": "https:\/\/apps.apple.com\/us\/developer\/%E5%AD%90%E8%A1%8E-%E7%8E%8B\/id1710838888?uo=4",
       "userRatingCountForCurrentVersion": 7,
       "isGameCenterEnabled": false,
       "appletvScreenshotUrls": [
       ],
       "genreIds": [
         "6002",
         "6006"
       ],
       "averageUserRatingForCurrentVersion": 5,
       "releaseDate": "2025-03-03T08:00:00Z",
       "trackId": 6740553198,
       "wrapperType": "software",
       "minimumOsVersion": "16.0",
       "formattedPrice": "$19.99",
       "primaryGenreId": 6002,
       "currentVersionReleaseDate": "2025-03-28T11:50:23Z",
       "userRatingCount": 7,
       "artistId": 1710838888,
       "trackContentRating": "17+",
       "artistName": "子衎 王",
       "price": 19.99,
       "trackCensoredName": "FlowDown - Open & Fast AI",
       "trackName": "FlowDown - Open & Fast AI",
       "kind": "software",
       "features": [
         "iosUniversal"
       ],
       "contentAdvisoryRating": "17+",
       "screenshotUrls": [
       ],
       "releaseNotes": "- Fixed issue where table border colors weren't updating correctly\n- Fixed a crash when quickly deleting messages\n- Allow sending empty messages when attachments are present\n- Added ability to directly select text",
       "isVppDeviceBasedLicensingEnabled": true,
       "sellerName": "子衎 王",
       "averageUserRating": 5,
       "advisories": [
         "Unrestricted Web Access"
       ]
     }
   ],
   "resultCount": 1
 }
 */
