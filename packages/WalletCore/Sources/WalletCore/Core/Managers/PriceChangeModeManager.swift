import Combine
import HsExtensions

class PriceChangeModeManager {
    private let keyPriceChangeMode = "price-change-mode"

    private let storage: SharedLocalStorage

    @PostPublished var priceChangeMode: PriceChangeMode {
        didSet {
            storage.set(value: priceChangeMode.rawValue, for: keyPriceChangeMode)
        }
    }

    var day1WatchlistPeriod: WatchlistTimePeriod {
        switch priceChangeMode {
        case .hour24: .hour24
        case .day1: .day1
        }
    }

    init(storage: SharedLocalStorage) {
        self.storage = storage

        if let rawValue: String = storage.value(for: keyPriceChangeMode), let value = PriceChangeMode(rawValue: rawValue) {
            priceChangeMode = value
        } else {
            priceChangeMode = .hour24
        }
    }

    func convert(period: WatchlistTimePeriod) -> WatchlistTimePeriod {
        guard [WatchlistTimePeriod.day1, .hour24].contains(period) else {
            return period
        }

        return day1WatchlistPeriod
    }
}
