import Combine
import HsExtensions
import MarketKit

class PriceChangeModeManager {
    private let keyPriceChangeMode = "price-change-mode"

    private let userDefaultsStorage: UserDefaultsStorage

    @PostPublished var priceChangeMode: PriceChangeMode {
        didSet {
            userDefaultsStorage.set(value: priceChangeMode.rawValue, for: keyPriceChangeMode)
        }
    }

    var day1Period: HsTimePeriod {
        switch priceChangeMode {
        case .hour24: .hour24
        case .day1: .day1
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

    func convert(period: HsTimePeriod) -> HsTimePeriod {
        guard [HsTimePeriod.day1, .hour24].contains(period) else {
            return period
        }

        return day1Period
    }
}
