import Combine
import HsExtensions

class WatchlistManager {
    private let keyCoinUids = "watchlist-coin-uids"
    private let keySortBy = "watchlist-sort-by"
    private let keyTimePeriod = "watchlist-time-period"
    private let keyShowSignals = "watchlist-show-signals"

    private let widgetRefresher: IWidgetRefresher?
    private let storage: SharedLocalStorage
    private let priceChangeModeManager: PriceChangeModeManager
    private var cancellables = Set<AnyCancellable>()

    private let coinUidsSubject = PassthroughSubject<[String], Never>()
    private let showSignalsUpdatedSubject = PassthroughSubject<Void, Never>()

    var coinUids: [String] {
        didSet {
            coinUidSet = Set(coinUids)
            coinUidsSubject.send(coinUids)

            storage.set(value: coinUids, for: keyCoinUids)

            widgetRefresher?.refreshWatchlist()
        }
    }

    private var coinUidSet: Set<String>

    var sortBy: WatchlistSortBy {
        didSet {
            storage.set(value: sortBy.rawValue, for: keySortBy)
            widgetRefresher?.refreshWatchlist()
        }
    }

    @PostPublished var timePeriod: WatchlistTimePeriod {
        didSet {
            guard timePeriod != oldValue else {
                return
            }

            storage.set(value: timePeriod.rawValue, for: keyTimePeriod)
            widgetRefresher?.refreshWatchlist()
        }
    }

    var showSignals: Bool {
        didSet {
            storage.set(value: showSignals, for: keyShowSignals)
            showSignalsUpdatedSubject.send()
            // widgetRefresher?.refreshWatchlist()
        }
    }

    init(widgetRefresher: IWidgetRefresher? = nil, storage: SharedLocalStorage, priceChangeModeManager: PriceChangeModeManager) {
        self.widgetRefresher = widgetRefresher
        self.storage = storage
        self.priceChangeModeManager = priceChangeModeManager

        coinUids = storage.value(for: keyCoinUids) ?? []
        coinUidSet = Set(coinUids)

        let sortByRaw: String? = storage.value(for: keySortBy)
        sortBy = sortByRaw.flatMap { WatchlistSortBy(rawValue: $0) } ?? .manual

        let timePeriodRaw: String? = storage.value(for: keyTimePeriod)
        timePeriod = timePeriodRaw.flatMap { WatchlistTimePeriod(rawValue: $0) } ?? priceChangeModeManager.day1WatchlistPeriod

        showSignals = storage.value(for: keyShowSignals) ?? true

        widgetRefresher?.refreshWatchlist()

        priceChangeModeManager.$priceChangeMode
            .sink { [weak self] _ in
                self?.syncPeriod()
            }
            .store(in: &cancellables)
    }

    private func syncPeriod() {
        timePeriod = priceChangeModeManager.convert(period: timePeriod)
    }
}

extension WatchlistManager {
    var coinUidsPublisher: AnyPublisher<[String], Never> {
        coinUidsSubject.eraseToAnyPublisher()
    }

    var showSignalsUpdatedPublisher: AnyPublisher<Void, Never> {
        showSignalsUpdatedSubject.eraseToAnyPublisher()
    }

    var timePeriods: [WatchlistTimePeriod] {
        [priceChangeModeManager.day1WatchlistPeriod, .week1, .month1, .month3]
    }

    func set(coinUids: [String]) {
        self.coinUids = coinUids
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
