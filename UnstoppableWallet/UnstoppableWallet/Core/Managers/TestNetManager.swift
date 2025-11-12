import Foundation
import HsExtensions

class TestNetManager {
    private let keyTestNetEnabled = "test-net-enabled"
    private let keyMayaStagenetEnabled = "maya-stage-net-enabled"

    private let userDefaultsStorage: UserDefaultsStorage

    @PostPublished private(set) var testNetEnabled: Bool
    @PostPublished private(set) var mayaStagenetEnabled: Bool

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        testNetEnabled = userDefaultsStorage.value(for: keyTestNetEnabled) ?? false
        mayaStagenetEnabled = userDefaultsStorage.value(for: keyMayaStagenetEnabled) ?? false
    }
}

extension TestNetManager {
    func set(testNetEnabled: Bool) {
        self.testNetEnabled = testNetEnabled
        userDefaultsStorage.set(value: testNetEnabled, for: keyTestNetEnabled)
    }

    func set(mayaStagenetEnabled: Bool) {
        self.mayaStagenetEnabled = mayaStagenetEnabled
        userDefaultsStorage.set(value: mayaStagenetEnabled, for: keyMayaStagenetEnabled)
    }
}
