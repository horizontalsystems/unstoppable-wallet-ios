import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketWatchlistViewModel: ObservableObject {
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager
    private let watchlistManager = App.shared.watchlistManager
    private let userDefaultsStorage = App.shared.userDefaultsStorage

    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private var coinUids = [String]()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @Published var state: State = .loading

    @Published var sortBy: WatchlistSortBy {
        didSet {
            syncState()
            watchlistManager.sortBy = sortBy
        }
    }

    @Published var timePeriod: WatchlistTimePeriod {
        didSet {
            syncState()
            watchlistManager.timePeriod = timePeriod
        }
    }

    @Published var showSignals: Bool {
        didSet {
            syncState()
            watchlistManager.showSignals = showSignals
        }
    }

    init() {
        sortBy = watchlistManager.sortBy
        timePeriod = watchlistManager.timePeriod
        showSignals = watchlistManager.showSignals
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

    func load() {
        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.syncMarketInfos()
            }
            .store(in: &cancellables)

        watchlistManager.coinUidsPublisher
            .sink { [weak self] _ in self?.syncCoinUids() }
            .store(in: &cancellables)

        syncCoinUids()
    }

    func refresh() async {
        await _syncMarketInfos()
    }

    func remove(coinUid: String) {
        watchlistManager.remove(coinUid: coinUid)
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
