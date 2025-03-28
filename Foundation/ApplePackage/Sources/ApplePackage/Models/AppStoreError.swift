import Foundation

public enum AppStoreError: Error {
    case invalidCredentials
    case passwordTokenExpired
    case licenseNotFound
    case temporarilyUnavailable
    case subscriptionRequired
    case authCodeRequired
    case licenseRequired
    case invalidResponse
    case appNotFound
    case networkError(Error)
    case custom(String, Any? = nil)

    var localizedDescription: String {
        switch self {
        case .invalidCredentials:
            String(localized: "login_credentials_invalid")
        case .passwordTokenExpired:
            String(localized: "password_token_expired")
        case .licenseNotFound:
            String(localized: "license_not_found")
        case .temporarilyUnavailable:
            String(localized: "service_temporarily_unavailable")
        case .subscriptionRequired:
            String(localized: "subscription_required")
        case .authCodeRequired:
            String(localized: "auth_code_required")
        case .licenseRequired:
            String(localized: "license_required")
        case .invalidResponse:
            String(localized: "server_invalid_response")
        case .appNotFound:
            String(localized: "app_not_found")
        case let .networkError(error):
            String(localized: "network_error_format").replacingOccurrences(of: "{error}", with: error.localizedDescription)
        case let .custom(message, _):
            message
        }
    }
}
