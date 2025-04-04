import Foundation

extension AppStoreService: AppStoreAuthenticationService {
    public nonisolated
    func login(email: String, password: String, authCode: String = "") async throws -> Account {
        let baseURL = URL(string: "https://\(Constants.privateAppStoreAPIDomain)\(Constants.privateAppStoreAPIPathAuthenticate)")!

        var currentURL = baseURL
        var currentAttempt = 1

        while currentAttempt <= 4 {
            do {
                let (response, responseHeaders) = try await HTTPClient().request(
                    url: currentURL,
                    method: "POST",
                    headers: [
                        // dont know why but this should work
                        "Content-Type": "application/x-www-form-urlencoded",
                    ],
                    body: PropertyListSerialization.data(
                        fromPropertyList: [
                            "appleId": email,
                            "attempt": String(currentAttempt),
                            "guid": guid,
                            "password": "\(password)\(authCode)",
                            "rmp": "0",
                            "why": "signIn",
                        ],
                        format: .xml,
                        options: 0
                    ),
                    responseFormat: .xml
                ) as (LoginResponse, [String: String])

                if let location = responseHeaders["location"], let locationURL = URL(string: location) {
                    currentURL = locationURL
                    currentAttempt += 1
                    continue
                }

                if currentAttempt == 1, response.failureType == Constants.failureTypeInvalidCredentials {
                    currentAttempt += 1
                    continue
                }

                if response.failureType?.isEmpty ?? true,
                   authCode.isEmpty,
                   response.customerMessage == Constants.customerMessageBadLogin
                {
                    throw AppStoreError.authCodeRequired
                }

                if let failureType = response.failureType, !failureType.isEmpty {
                    switch failureType {
                    case Constants.failureTypePasswordTokenExpired:
                        throw AppStoreError.passwordTokenExpired
                    case Constants.failureTypeInvalidCredentials:
                        throw AppStoreError.invalidCredentials
                    default:
                        if let message = response.customerMessage, !message.isEmpty {
                            throw AppStoreError.custom(message)
                        } else {
                            throw AppStoreError.custom(String(localized: "login_failed", bundle: .module))
                        }
                    }
                }

                guard let passwordToken = response.passwordToken,
                      let dsID = response.dsPersonId,
                      let storeFront = responseHeaders["X-Set-Apple-Store-Front".lowercased()],
                      let accountInfo = response.accountInfo
                else {
                    throw AppStoreError.invalidResponse
                }

                let name = [accountInfo.address?.firstName, accountInfo.address?.lastName]
                    .compactMap(\.self)
                    .joined(separator: " ")

                return Account(
                    email: accountInfo.appleId ?? email,
                    passwordToken: passwordToken,
                    directoryServicesID: dsID,
                    name: name,
                    storeFront: storeFront,
                    password: password
                )
            } catch let error as AppStoreError {
                throw error
            } catch {
                if currentAttempt >= 4 { break }
                currentAttempt += 1
            }
        }

        throw AppStoreError.custom(String(localized: "login_failed_too_many_attempts", bundle: .module))
    }
}

private extension AppStoreService {
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
}
