import Foundation
import HsExtensions
import StorageKit

class SubscriptionManager {
    private let keyAuthToken = "subscription-auth-token"

    private let localStorage: StorageKit.ILocalStorage

    @PostPublished private(set) var authToken: String?

    init(localStorage: StorageKit.ILocalStorage) {
        self.localStorage = localStorage

        authToken = localStorage.value(for: keyAuthToken)
    }

}

extension SubscriptionManager {

    func set(authToken: String) {
        self.authToken = authToken
        localStorage.set(value: authToken, for: keyAuthToken)
    }

    func invalidateAuthToken() {
        authToken = nil
        localStorage.set(value: authToken, for: keyAuthToken)
    }

}
