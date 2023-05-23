import Foundation
import HsExtensions
import StorageKit

class TestNetManager {
    private let keyTestNetEnabled = "test-net-enabled"

    private let localStorage: StorageKit.ILocalStorage

    @PostPublished private(set) var testNetEnabled: Bool

    init(localStorage: StorageKit.ILocalStorage) {
        self.localStorage = localStorage

        testNetEnabled = localStorage.value(for: keyTestNetEnabled) ?? false
    }

}

extension TestNetManager {

    func set(testNetEnabled: Bool) {
        self.testNetEnabled = testNetEnabled
        localStorage.set(value: testNetEnabled, for: keyTestNetEnabled)
    }

}
