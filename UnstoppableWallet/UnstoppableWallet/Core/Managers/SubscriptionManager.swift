import Foundation
import HsExtensions
import StorageKit
import MarketKit

class SubscriptionManager {
    private let keyAuthToken = "subscription-auth-token"

    private let localStorage: StorageKit.ILocalStorage
    private let marketKit: MarketKit.Kit

    @PostPublished private(set) var authToken: String?

    init(localStorage: StorageKit.ILocalStorage, marketKit: MarketKit.Kit) {
        self.localStorage = localStorage
        self.marketKit = marketKit

        authToken = localStorage.value(for: keyAuthToken)
        marketKit.set(proAuthToken: authToken)
    }

}

extension SubscriptionManager {

    func set(authToken: String) {
        marketKit.set(proAuthToken: authToken)
        self.authToken = authToken
        localStorage.set(value: authToken, for: keyAuthToken)
    }

    func invalidateAuthToken() {
        marketKit.set(proAuthToken: nil)
        authToken = nil
        localStorage.set(value: authToken, for: keyAuthToken)
    }

}
