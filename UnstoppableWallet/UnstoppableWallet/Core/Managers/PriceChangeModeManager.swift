import Combine
import HsExtensions

class PriceChangeModeManager {
    private let keyPriceChangeMode = "price-change-mode"

    private let userDefaultsStorage: UserDefaultsStorage

    @PostPublished var priceChangeMode: PriceChangeMode {
        didSet {
            userDefaultsStorage.set(value: priceChangeMode.rawValue, for: keyPriceChangeMode)
        }
    }

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        if let rawValue: String = userDefaultsStorage.value(for: keyPriceChangeMode), let value = PriceChangeMode(rawValue: rawValue) {
            priceChangeMode = value
        } else {
            priceChangeMode = .hour24
        }
    }
}
