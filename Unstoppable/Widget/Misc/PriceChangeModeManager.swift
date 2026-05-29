import Combine
import HsExtensions

class PriceChangeModeManager {
    private let keyPriceChangeMode = "price-change-mode"

    let day1WatchlistPeriod: WatchlistTimePeriod

    init(storage: SharedLocalStorage) {
        let priceChangeMode: PriceChangeMode

        if let rawValue: String = storage.value(for: keyPriceChangeMode), let value = PriceChangeMode(rawValue: rawValue) {
            priceChangeMode = value
        } else {
            priceChangeMode = .hour24
        }

        switch priceChangeMode {
        case .hour24: day1WatchlistPeriod = .hour24
        case .day1: day1WatchlistPeriod = .day1
        }
    }
}
