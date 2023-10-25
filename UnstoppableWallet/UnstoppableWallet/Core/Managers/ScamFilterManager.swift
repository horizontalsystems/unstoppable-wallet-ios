import Combine
import HsExtensions

class ScamFilterManager {
    private let keyScamFilterEnabled = "scam-filter-enabled"

    private let userDefaultsStorage: UserDefaultsStorage

    @PostPublished var scamFilterEnabled: Bool {
        didSet {
            userDefaultsStorage.set(value: scamFilterEnabled, for: keyScamFilterEnabled)
        }
    }

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        scamFilterEnabled = userDefaultsStorage.value(for: keyScamFilterEnabled) ?? true
    }
}
