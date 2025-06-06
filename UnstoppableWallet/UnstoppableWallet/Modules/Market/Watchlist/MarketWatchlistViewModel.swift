import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketWatchlistViewModel: ObservableObject {
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager
    private let watchlistManager = App.shared.watchlistManager
    private let userDefaultsStorage = App.shared.userDefaultsStorage
    private let appManager = App.shared.appManager
    private let purchaseManager = App.shared.purchaseManager
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private var coinUids = [String]()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @Published private(set) var tradeSignalsEnabled: Bool = false
    @Published var state: State = .loading

    @Published var sortBy: WatchlistSortBy {
        didSet {
            stat(page: .markets, section: .watchlist, event: .switchSortType(sortType: sortBy.statSortType))
            syncState()
            watchlistManager.sortBy = sortBy
        }
    }

    @Published var timePeriod: WatchlistTimePeriod {
        didSet {
            stat(page: .markets, section: .watchlist, event: .switchPeriod(period: timePeriod.statPeriod))
            syncState()

            if timePeriod != oldValue {
                watchlistManager.timePeriod = timePeriod
            }
        }
    }

    @Published var showSignals: Bool

    init() {
        let tradeSignalsEnabled = purchaseManager.activated(.tradeSignals)

        sortBy = watchlistManager.sortBy
        timePeriod = watchlistManager.timePeriod
        showSignals = tradeSignalsEnabled && watchlistManager.showSignals
        self.tradeSignalsEnabled = tradeSignalsEnabled

        watchlistManager.$timePeriod
            .sink { [weak self] timePeriod in
                self?.timePeriod = timePeriod
            }
            .store(in: &cancellables)

        watchlistManager.showSignalsUpdatedPublisher
            .sink { [weak self] in
                self?.syncShowSignals()
            }
            .store(in: &cancellables)

        purchaseManager.$activeFeatures
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeFeatures in
                self?.tradeSignalsEnabled = activeFeatures.contains(.tradeSignals)
                self?.syncShowSignals()
            }
            .store(in: &cancellables)
    }

    private func syncShowSignals() {
        showSignals = tradeSignalsEnabled && watchlistManager.showSignals
    }

    private func syncCoinUids() {
        let coinUids = watchlistManager.coinUids

        if case .loaded = internalState, coinUids == self.coinUids {
            return
        }

        self.coinUids = coinUids

        if case let .loaded(marketInfos, signals) = internalState {
            let newMarketInfos = marketInfos.filter { marketInfo in
                coinUids.contains(marketInfo.fullCoin.coin.uid)
            }

            if newMarketInfos.count == coinUids.count {
                internalState = .loaded(marketInfos: newMarketInfos, signals: signals)
                return
            }
        }

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        tasks = Set()

        Task { [weak self] in
            await self?._syncMarketInfos()
        }.store(in: &tasks)
    }

    private func _syncMarketInfos() async {
        if coinUids.isEmpty {
            await MainActor.run { [weak self] in
                self?.internalState = .loaded(marketInfos: [], signals: [:])
            }
            return
        }

        if case .failed = internalState {
            await MainActor.run { [weak self] in
                self?.internalState = .loading
            }
        }

        do {
            async let _marketInfos = try marketKit.marketInfos(coinUids: coinUids, currencyCode: currency.code)
            async let _signals = try marketKit.signals(coinUids: coinUids)

            let (marketInfos, signals) = try await (_marketInfos, _signals)

            let marketInfoMap = marketInfos.reduce(into: [String: MarketInfo]()) { $0[$1.fullCoin.coin.uid] = $1 }
            let orderedMarketInfos = coinUids.compactMap { marketInfoMap[$0] }

            await MainActor.run { [weak self] in
                self?.internalState = .loaded(marketInfos: orderedMarketInfos, signals: signals)
            }
        } catch {
            await MainActor.run { [weak self] in
                self?.internalState = .failed(error: error)
            }
        }
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = .loading
        case let .loaded(marketInfos, signals):
            state = .loaded(marketInfos: marketInfos.sorted(sortBy: sortBy, timePeriod: timePeriod), signals: signals)
        case let .failed(error):
            state = .failed(error: error)
        }
    }
}

extension MarketWatchlistViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var timePeriods: [WatchlistTimePeriod] {
        watchlistManager.timePeriods
    }

    func load() {
        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.syncMarketInfos()
            }
            .store(in: &cancellables)

        appManager.willEnterForegroundPublisher
            .sink { [weak self] in self?.syncMarketInfos() }
            .store(in: &cancellables)

        watchlistManager.coinUidsPublisher
            .sink { [weak self] _ in self?.syncCoinUids() }
            .store(in: &cancellables)

        syncCoinUids()
    }

    func refresh() async {
        await _syncMarketInfos()
    }

    func set(showSignals: Bool) {
        stat(page: .markets, section: .watchlist, event: .showSignals(shown: showSignals))
        syncState()
        watchlistManager.showSignals = showSignals

        syncShowSignals()
    }

    func remove(coinUid: String) {
        watchlistManager.remove(coinUid: coinUid)
        stat(page: .markets, section: .watchlist, event: .removeFromWatchlist(coinUid: coinUid))
    }

    func move(source: IndexSet, destination: Int) {
        guard case let .loaded(marketInfos, signals) = internalState else {
            return
        }

        var newCoinUids = coinUids
        var newMarketInfos = marketInfos

        newCoinUids.move(fromOffsets: source, toOffset: destination)
        newMarketInfos.move(fromOffsets: source, toOffset: destination)

        coinUids = newCoinUids
        internalState = .loaded(marketInfos: newMarketInfos, signals: signals)

        watchlistManager.set(coinUids: coinUids)
    }
}

extension MarketWatchlistViewModel {
    enum State {
        case loading
        case loaded(marketInfos: [MarketInfo], signals: [String: TechnicalAdvice.Advice])
        case failed(error: Error)
    }
}
