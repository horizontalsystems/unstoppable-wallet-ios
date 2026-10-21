import Foundation
import HsToolKit
import Testing
@testable import WalletCore

private final class EphemeralUserDefaultsStorage: UserDefaultsStorage {
    private var values = [String: Any]()

    override func value<T>(for key: String) -> T? {
        values[key] as? T
    }

    override func set(value: (some Any)?, for key: String) {
        values[key] = value
    }
}

// The provider score shown on the swap screen comes from the backend's `amlPolicy`, cached across launches
struct MultiSwapProviderManagerAmlPolicyTests {
    @Test func restoresCachedPolicies() {
        let manager = manager(amlPolicies: #"{"THORCHAIN":"excellent","QUICKEX":"good","NEAR":"fair"}"#)

        #expect(manager.amlPolicy(providerId: "THORCHAIN") == .excellent)
        #expect(manager.amlPolicy(providerId: "QUICKEX") == .good)
        #expect(manager.amlPolicy(providerId: "NEAR") == .fair)
    }

    @Test func unknownPolicyIsNil() {
        let manager = manager(amlPolicies: #"{"X":"superb"}"#)
        #expect(manager.amlPolicy(providerId: "X") == nil)
    }

    @Test func missingProviderIsNil() {
        let manager = manager(amlPolicies: #"{"THORCHAIN":"excellent"}"#)
        #expect(manager.amlPolicy(providerId: "NEAR") == nil)
    }

    @Test func caseInsensitive() {
        let manager = manager(amlPolicies: #"{"QUICKEX":"GOOD"}"#)
        #expect(manager.amlPolicy(providerId: "QUICKEX") == .good)
    }

    // every cache seeded and the sync timestamp fresh, so init restores from storage and never fetches
    private func manager(amlPolicies: String) -> MultiSwapProviderManager {
        let localStorage = LocalStorage(userDefaultsStorage: EphemeralUserDefaultsStorage())
        localStorage.uSwapAmlPolicies = amlPolicies
        localStorage.uSwapExecutionTypes = "{}"
        localStorage.uSwapSuspensions = "{}"
        localStorage.uSwapSplitProviders = ""
        localStorage.uSwapProviders = "THORCHAIN,QUICKEX,NEAR"
        localStorage.swapProvidersLastSyncTimestamp = Date().timeIntervalSince1970

        return MultiSwapProviderManager(localStorage: localStorage, networkManager: NetworkManager(), apiKey: nil)
    }
}
