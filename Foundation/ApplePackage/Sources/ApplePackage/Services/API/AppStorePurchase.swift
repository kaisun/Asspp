import Foundation

extension AppStoreService: AppStorePurchaseService {
    public nonisolated
    func purchase(account: Account, app: AppPackage) async throws {
        if app.price > 0 {
            throw AppStoreError.custom(String(localized: "paid_app_not_supported", bundle: .module))
        }

        do {
            try await purchaseWithParams(
                account: account,
                app: app,
                pricingParameters: Constants.pricingParameterAppStore
            )
        } catch AppStoreError.temporarilyUnavailable {
            try await purchaseWithParams(
                account: account,
                app: app,
                pricingParameters: Constants.pricingParameterAppleArcade
            )
        }
    }

    func purchaseWithParams(account: Account, app: AppPackage, pricingParameters: String) async throws {
        let url = URL(string: "https://\(Constants.privateAppStoreAPIDomain)\(Constants.privateAppStoreAPIPathPurchase)")!

        let headers = [
            "Content-Type": "application/x-apple-plist",
            "iCloud-DSID": account.directoryServicesID,
            "X-Dsid": account.directoryServicesID,
            "X-Apple-Store-Front": account.storeFront,
            "X-Token": account.passwordToken,
        ]

        let params: [String: Any] = [
            "appExtVrsId": "0",
            "hasAskedToFulfillPreorder": "true",
            "buyWithoutAuthorization": "true",
            "hasDoneAgeCheck": "true",
            "guid": guid,
            "needDiv": "0",
            "origPage": "Software-\(app.id)",
            "origPageLocation": "Buy",
            "price": "0",
            "pricingParameters": pricingParameters,
            "productType": "C",
            "salableAdamId": app.id,
        ]

        let propertyListData = try PropertyListSerialization.data(
            fromPropertyList: params,
            format: .xml,
            options: 0
        )

        struct PurchaseResponse: Decodable {
            let failureType: String?
            let customerMessage: String?
            let jingleDocType: String?
            let status: Int?
        }

        let (response, _) = try await HTTPClient().request(
            url: url,
            method: "POST",
            headers: headers,
            body: propertyListData,
            responseFormat: .xml
        ) as (PurchaseResponse, [String: String])

        if response.failureType == Constants.failureTypeTemporarilyUnavailable {
            throw AppStoreError.temporarilyUnavailable
        }

        if response.customerMessage == Constants.customerMessageSubscriptionRequired {
            throw AppStoreError.subscriptionRequired
        }

        if response.failureType == Constants.failureTypePasswordTokenExpired {
            throw AppStoreError.passwordTokenExpired
        }

        if let failureType = response.failureType, !failureType.isEmpty {
            if let message = response.customerMessage, !message.isEmpty {
                throw AppStoreError.custom(message)
            }
            throw AppStoreError.custom(String(localized: "failed_to_purchase", bundle: .module))
        }

        if response.jingleDocType != "purchaseSuccess" || response.status != 0 {
            throw AppStoreError.custom(String(localized: "purchase_failed", bundle: .module))
        }
    }
}
