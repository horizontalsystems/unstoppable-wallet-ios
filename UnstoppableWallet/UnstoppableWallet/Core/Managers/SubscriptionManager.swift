import Foundation
import HsExtensions
import StorageKit
import MarketKit
import HsToolKit

class SubscriptionManager {
    private let keyAuthToken = "subscription-auth-token"

    private let localStorage: StorageKit.ILocalStorage
    private let marketKit: MarketKit.Kit

    private var authToken: String? {
        didSet {
            isAuthenticated = authToken != nil
        }
    }

    @DistinctPublished private(set) var isAuthenticated: Bool

    init(localStorage: StorageKit.ILocalStorage, marketKit: MarketKit.Kit) {
        self.localStorage = localStorage
        self.marketKit = marketKit

//        authToken = localStorage.value(for: keyAuthToken)
//        marketKit.set(proAuthToken: authToken)
//        isAuthenticated = authToken != nil

        authToken = nil
        isAuthenticated = true
    }

    private func invalidateAuthToken() {
        marketKit.set(proAuthToken: nil)
        authToken = nil
        localStorage.set(value: authToken, for: keyAuthToken)
    }

}

extension SubscriptionManager {

    func fetch<T>(request: () async throws -> T, onSuccess: (T) -> (), onInvalidAuthToken: () -> (), onFailure: (Error) -> ()) async throws {
        do {
            let result = try await request()
            onSuccess(result)
        } catch {
//            if let responseError = error as? NetworkManager.ResponseError, (responseError.statusCode == 401 || responseError.statusCode == 403) {
//                invalidateAuthToken()
//                onInvalidAuthToken()
//            } else {
//                onFailure(error)
//            }

            onFailure(error)
        }
    }

    func set(authToken: String) {
//        marketKit.set(proAuthToken: authToken)
//        self.authToken = authToken
//        localStorage.set(value: authToken, for: keyAuthToken)
    }

}
