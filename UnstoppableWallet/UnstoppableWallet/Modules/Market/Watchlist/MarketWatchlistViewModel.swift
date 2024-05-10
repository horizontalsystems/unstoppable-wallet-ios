import Combine
import Foundation
import HsExtensions
import MarketKit
import RxSwift

class MarketWatchlistViewModel: ObservableObject {
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager
    private let favoritesManager = App.shared.favoritesManager

    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private var coinUids = [String]()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @Published var state: State = .loading

    var sortBy: MarketModule.SortBy = .gainers {
        didSet {
            syncState()
        }
    }

    var priceChangePeriod: MarketModule.PriceChangePeriod = .hour24 {
        didSet {
            syncState()
        }
    }

    var showSignals: Bool = false {
        didSet {
            syncState()
        }
    }

    private func syncCoinUids() {
        coinUids = favoritesManager.allCoinUids

        if case let .loaded(marketInfos) = internalState {
            let newMarketInfos = marketInfos.filter { marketInfo in
                coinUids.contains(marketInfo.fullCoin.coin.uid)
            }

            if newMarketInfos.count == coinUids.count {
                internalState = .loaded(marketInfos: newMarketInfos)
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
                self?.internalState = .loaded(marketInfos: [])
            }
            return
        }

        if case .failed = internalState {
            await MainActor.run { [weak self] in
                self?.internalState = .loading
            }
        }

        do {
            let marketInfos = try await marketKit.marketInfos(coinUids: coinUids, currencyCode: currency.code)

            await MainActor.run { [weak self] in
                self?.internalState = .loaded(marketInfos: marketInfos)
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
        case let .loaded(marketInfos):
            state = .loaded(marketInfos: marketInfos.sorted(sortBy: sortBy, priceChangePeriod: priceChangePeriod))
        case let .failed(error):
            state = .failed(error: error)
        }
    }
}

extension MarketWatchlistViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var sortBys: [MarketModule.SortBy] {
        [.manual, .highestCap, .lowestCap, .gainers, .losers, .highestVolume, .lowestVolume]
    }

    var priceChangePeriods: [MarketModule.PriceChangePeriod] {
        [.hour24, .week1, .month1, .month3]
    }

    func load() {
        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.syncMarketInfos()
            }
            .store(in: &cancellables)

        subscribe(disposeBag, favoritesManager.coinUidsUpdatedObservable) { [weak self] in self?.syncCoinUids() }

        syncCoinUids()
    }

    func refresh() async {
        await _syncMarketInfos()
    }
}

extension MarketWatchlistViewModel {
    enum State {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }
}
