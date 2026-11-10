import Combine
import Foundation
import Testing
@testable import WalletCore

struct BrandColorManagerTests {
    private func withSuite(_ body: (UserDefaults) throws -> Void) rethrows {
        let suiteName = "BrandColorManagerTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        try body(userDefaults)
    }

    @Test func defaultsToOrangeWhenNothingStored() {
        withSuite { userDefaults in
            let manager = BrandColorManager(userDefaults: userDefaults)

            #expect(manager.brandColor == .orange)
            #expect(userDefaults.string(forKey: BrandColorManager.userDefaultsKey) == nil)
        }
    }

    @Test func readsStoredJacob() {
        withSuite { userDefaults in
            userDefaults.set("jacob", forKey: BrandColorManager.userDefaultsKey)

            let manager = BrandColorManager(userDefaults: userDefaults)

            #expect(manager.brandColor == .jacob)
        }
    }

    @Test func fallsBackToOrangeOnUnknownRawValue() {
        withSuite { userDefaults in
            userDefaults.set("purple", forKey: BrandColorManager.userDefaultsKey)

            let manager = BrandColorManager(userDefaults: userDefaults)

            #expect(manager.brandColor == .orange)
        }
    }

    @Test func persistsRawValueOnSet() {
        withSuite { userDefaults in
            let manager = BrandColorManager(userDefaults: userDefaults)
            manager.set(brandColor: .jacob)

            #expect(userDefaults.string(forKey: BrandColorManager.userDefaultsKey) == "jacob")
            #expect(BrandColorManager(userDefaults: userDefaults).brandColor == .jacob)
        }
    }

    @Test func setSkipsEqualValue() {
        withSuite { userDefaults in
            let manager = BrandColorManager(userDefaults: userDefaults)
            var emissions = [BrandColor]()
            let cancellable = manager.$brandColor.sink { emissions.append($0) }

            manager.set(brandColor: .jacob)
            manager.set(brandColor: .jacob)

            #expect(emissions == [.jacob])
            cancellable.cancel()
        }
    }

    @Test func defaultAndOrder() {
        #expect(BrandColor.default == .orange)
        #expect(BrandColor.allCases == [.orange, .jacob])
    }
}
