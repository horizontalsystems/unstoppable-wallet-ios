import Combine
import WidgetKit

class WatchlistManager {
    private let keyCoinUids = "watchlist-coin-uids"
    private let keySortBy = "watchlist-sort-by"
    private let keyTimePeriod = "watchlist-time-period"
    private let keyShowSignals = "watchlist-show-signals"

    private let storage: SharedLocalStorage

    private let coinUidsSubject = PassthroughSubject<[String], Never>()

    var coinUids: [String] {
        didSet {
            coinUidSet = Set(coinUids)
            coinUidsSubject.send(coinUids)

            storage.set(value: coinUids, for: keyCoinUids)

            WidgetCenter.shared.reloadTimelines(ofKind: AppWidgetConstants.watchlistWidgetKind)
        }
    }

    private var coinUidSet: Set<String>

    var sortBy: WatchlistSortBy {
        didSet {
            storage.set(value: sortBy.rawValue, for: keySortBy)
            WidgetCenter.shared.reloadTimelines(ofKind: AppWidgetConstants.watchlistWidgetKind)
        }
    }

    var timePeriod: WatchlistTimePeriod {
        didSet {
            storage.set(value: timePeriod.rawValue, for: keyTimePeriod)
            WidgetCenter.shared.reloadTimelines(ofKind: AppWidgetConstants.watchlistWidgetKind)
        }
    }

    var showSignals: Bool {
        didSet {
            storage.set(value: showSignals, for: keyShowSignals)
            // WidgetCenter.shared.reloadTimelines(ofKind: AppWidgetConstants.watchlistWidgetKind)
        }
    }

    init(storage: SharedLocalStorage) {
        self.storage = storage

        coinUids = storage.value(for: keyCoinUids) ?? []
        coinUidSet = Set(coinUids)

        let sortByRaw: String? = storage.value(for: keySortBy)
        sortBy = sortByRaw.flatMap { WatchlistSortBy(rawValue: $0) } ?? .manual

        let timePeriodRaw: String? = storage.value(for: keyTimePeriod)
        timePeriod = timePeriodRaw.flatMap { WatchlistTimePeriod(rawValue: $0) } ?? .day1

        showSignals = storage.value(for: keyShowSignals) ?? true

        WidgetCenter.shared.reloadTimelines(ofKind: AppWidgetConstants.watchlistWidgetKind)
    }
}

extension WatchlistManager {
    var coinUidsPublisher: AnyPublisher<[String], Never> {
        coinUidsSubject.eraseToAnyPublisher()
    }

    func add(coinUid: String) {
        guard !coinUids.contains(coinUid) else {
            return
        }

        coinUids.append(coinUid)
    }

    func add(coinUids: [String]) {
        let coinUids = coinUids.filter { !self.coinUids.contains($0) }
        self.coinUids.append(contentsOf: coinUids)
    }

    func removeAll() {
        coinUids = []
    }

    func remove(coinUid: String) {
        guard let index = coinUids.firstIndex(of: coinUid) else {
            return
        }

        coinUids.remove(at: index)
    }

    func isWatched(coinUid: String) -> Bool {
        coinUidSet.contains(coinUid)
    }
}
