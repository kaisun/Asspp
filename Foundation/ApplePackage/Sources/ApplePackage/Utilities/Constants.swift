import Foundation

public enum Constants {
    // 错误代码
    static let failureTypeInvalidCredentials = "-5000"
    static let failureTypePasswordTokenExpired = "2034"
    static let failureTypeLicenseNotFound = "9610"
    static let failureTypeTemporarilyUnavailable = "2059"

    // 错误消息
    static let customerMessageBadLogin = "MZFinance.BadLogin.Configurator_message"
    static let customerMessageSubscriptionRequired = String(localized: "subscription_required_message")

    // API 域名和路径
    static let iTunesAPIDomain = "itunes.apple.com"
    static let iTunesAPIPathSearch = "/search"
    static let iTunesAPIPathLookup = "/lookup"

    static let privateAppStoreAPIDomainPrefixWithoutAuthCode = "p25"
    static let privateAppStoreAPIDomainPrefixWithAuthCode = "p71"
    static let privateAppStoreAPIDomain = "buy.itunes.apple.com"
    static let privateAppStoreAPIPathAuthenticate = "/WebObjects/MZFinance.woa/wa/authenticate"
    static let privateAppStoreAPIPathPurchase = "/WebObjects/MZFinance.woa/wa/buyProduct"
    static let privateAppStoreAPIPathDownload = "/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct"

    // HTTP 头
    static let httpHeaderStoreFront = "X-Set-Apple-Store-Front"

    // 定价参数
    static let pricingParameterAppStore = "STDQ"
    static let pricingParameterAppleArcade = "GAME"

    // 用户代理
    static let defaultUserAgent = "Configurator/2.17 (Macintosh; OS X 15.2; 24C5089c) AppleWebKit/0620.1.16.11.6"
}
