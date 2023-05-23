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
        print("SET: \(authToken)")
        self.authToken = authToken
        localStorage.set(value: authToken, for: keyAuthToken)
    }

    func invalidateAuthToken() {
        print("INVALIDATE: \(authToken)")
        authToken = nil
        localStorage.set(value: authToken, for: keyAuthToken)
    }

}
