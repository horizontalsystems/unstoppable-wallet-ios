import Combine
import HsExtensions

class WatchlistManager {
    private let keyCoinUids = "watchlist-coin-uids"
    private let keySortBy = "watchlist-sort-by"
    private let keyTimePeriod = "watchlist-time-period"

    let coinUids: [String]
    let sortBy: WatchlistSortBy
    let timePeriod: WatchlistTimePeriod

    init(storage: SharedLocalStorage, priceChangeModeManager: PriceChangeModeManager) {
        coinUids = storage.value(for: keyCoinUids) ?? []

        let sortByRaw: String? = storage.value(for: keySortBy)
        sortBy = sortByRaw.flatMap { WatchlistSortBy(rawValue: $0) } ?? .manual

        let timePeriodRaw: String? = storage.value(for: keyTimePeriod)
        timePeriod = timePeriodRaw.flatMap { WatchlistTimePeriod(rawValue: $0) } ?? priceChangeModeManager.day1WatchlistPeriod
    }
}
