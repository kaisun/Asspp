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
    case loginFailed
    case tooManyAttempts
}

extension AppStoreError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            String(localized: "login_credentials_invalid", bundle: .module)
        case .passwordTokenExpired:
            String(localized: "password_token_expired", bundle: .module)
        case .licenseNotFound:
            String(localized: "license_not_found", bundle: .module)
        case .temporarilyUnavailable:
            String(localized: "service_temporarily_unavailable", bundle: .module)
        case .subscriptionRequired:
            String(localized: "subscription_required", bundle: .module)
        case .authCodeRequired:
            String(localized: "auth_code_required", bundle: .module)
        case .licenseRequired:
            String(localized: "license_required", bundle: .module)
        case .invalidResponse:
            String(localized: "server_invalid_response", bundle: .module)
        case .appNotFound:
            String(localized: "app_not_found", bundle: .module)
        case .loginFailed:
            String(localized: "login_failed", bundle: .module)
        case .tooManyAttempts:
            String(localized: "login_failed_too_many_attempts", bundle: .module)
        case let .networkError(error):
            String(localized: "network_error \(error.localizedDescription)", bundle: .module)
        case let .custom(message, _):
            message
        }
    }
}
