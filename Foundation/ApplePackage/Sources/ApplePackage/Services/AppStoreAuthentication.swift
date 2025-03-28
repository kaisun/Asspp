import Foundation

extension AppStoreService: AppStoreAuthenticationService {
    public func login(email: String, password: String, authCode: String = "") async throws -> Account {
        var attempt = 1
        var redirectURL: URL? = nil

        while attempt <= 4 {
            let authURL = redirectURL ?? URL(string: "https://\(Constants.privateAppStoreAPIDomain)\(Constants.privateAppStoreAPIPathAuthenticate)")!

            let headers = ["Content-Type": "application/x-www-form-urlencoded"]

            let params: [String: String] = [
                "appleId": email,
                "attempt": String(attempt),
                "guid": guid,
                "password": "\(password)\(authCode)",
                "rmp": "0",
                "why": "signIn",
            ]

            let body = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)!

            struct LoginResponse: Codable {
                let failureType: String?
                let customerMessage: String?
                let accountInfo: AccountInfo?
                let dsPersonId: String?
                let passwordToken: String?

                struct AccountInfo: Codable {
                    let appleId: String?
                    let address: Address?

                    struct Address: Codable {
                        let firstName: String?
                        let lastName: String?
                    }
                }
            }

            do {
                let (response, responseHeaders) = try await HTTPClient.shared.request(
                    url: authURL,
                    method: "POST",
                    headers: headers,
                    body: body,
                    format: .xml
                ) as (LoginResponse, [String: String])

                if let location = responseHeaders["location"], let locationURL = URL(string: location) {
                    redirectURL = locationURL
                    attempt += 1
                    continue
                }

                if attempt == 1, response.failureType == Constants.failureTypeInvalidCredentials {
                    attempt += 1
                    continue
                }

                if response.failureType == nil, authCode.isEmpty, response.customerMessage == Constants.customerMessageBadLogin {
                    throw AppStoreError.authCodeRequired
                }

                if let failureType = response.failureType, !failureType.isEmpty {
                    if let message = response.customerMessage, !message.isEmpty {
                        throw AppStoreError.custom(message)
                    } else {
                        throw AppStoreError.custom(String(localized: "login_failed"))
                    }
                }

                if let passwordToken = response.passwordToken,
                   let dsID = response.dsPersonId,
                   let storeFront = responseHeaders[Constants.httpHeaderStoreFront],
                   let accountInfo = response.accountInfo
                {
                    let name = [accountInfo.address?.firstName, accountInfo.address?.lastName]
                        .compactMap(\.self)
                        .joined(separator: " ")

                    let account = Account(
                        email: accountInfo.appleId ?? email,
                        passwordToken: passwordToken,
                        directoryServicesID: dsID,
                        name: name,
                        storeFront: storeFront,
                        password: password
                    )

                    return account
                } else {
                    throw AppStoreError.invalidResponse
                }
            } catch {
                if attempt >= 4 {
                    throw AppStoreError.custom(String(localized: "login_failed_with_error").replacingOccurrences(of: "{error}", with: error.localizedDescription))
                }
                attempt += 1
            }
        }

        throw AppStoreError.custom(String(localized: "login_failed_too_many_attempts"))
    }
}
