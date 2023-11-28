import Foundation
import HsExtensions

class TestNetManager {
    private let keyTestNetEnabled = "test-net-enabled"

    private let userDefaultsStorage: UserDefaultsStorage

    @PostPublished private(set) var testNetEnabled: Bool

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        testNetEnabled = userDefaultsStorage.value(for: keyTestNetEnabled) ?? false
    }
}

extension TestNetManager {
    func set(testNetEnabled: Bool) {
        self.testNetEnabled = testNetEnabled
        userDefaultsStorage.set(value: testNetEnabled, for: keyTestNetEnabled)
    }
}
