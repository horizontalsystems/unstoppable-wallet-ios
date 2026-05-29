import Foundation
import HsExtensions
import HsToolKit
import MarketKit

class SubscriptionManager {
    private let keyAuthToken = "subscription-auth-token"

    private let userDefaultsStorage: UserDefaultsStorage
    private let marketKit: MarketKit.Kit

    private var authToken: String? {
        didSet {
            isAuthenticated = authToken != nil
        }
    }

    @DistinctPublished private(set) var isAuthenticated: Bool

    init(userDefaultsStorage: UserDefaultsStorage, marketKit: MarketKit.Kit) {
        self.userDefaultsStorage = userDefaultsStorage
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
        userDefaultsStorage.set(value: authToken, for: keyAuthToken)
    }
}

extension SubscriptionManager {
    func fetch<T>(request: () async throws -> T, onSuccess: (T) -> Void, onInvalidAuthToken _: () -> Void, onFailure: (Error) -> Void) async throws {
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

    func set(authToken _: String) {
//        marketKit.set(proAuthToken: authToken)
//        self.authToken = authToken
//        localStorage.set(value: authToken, for: keyAuthToken)
    }
}
