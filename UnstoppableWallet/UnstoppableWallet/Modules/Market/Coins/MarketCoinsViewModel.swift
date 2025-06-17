import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketCoinsViewModel: ObservableObject {
    private let marketKit = Core.shared.marketKit
    private let currencyManager = Core.shared.currencyManager
    private let appManager = Core.shared.appManager
    private let priceChangeModeManager = Core.shared.priceChangeModeManager

    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @Published var state: State = .loading

    var sortBy: MarketModule.SortBy = .gainers {
        didSet {
            stat(page: .markets, section: .coins, event: .switchSortType(sortType: sortBy.statSortType))
            syncState()
        }
    }

    var top: MarketModule.Top = .default {
        didSet {
            stat(page: .markets, event: .switchMarketTop(marketTop: top.statMarketTop))
            syncState()
        }
    }

    var timePeriod: HsTimePeriod {
        didSet {
            stat(page: .markets, section: .coins, event: .switchPeriod(period: timePeriod.statPeriod))
            syncState()
        }
    }

    init() {
        timePeriod = priceChangeModeManager.day1Period

        priceChangeModeManager.$priceChangeMode
            .sink { [weak self] _ in
                self?.syncPeriod()
            }
            .store(in: &cancellables)
    }

    private func syncPeriod() {
        timePeriod = priceChangeModeManager.convert(period: timePeriod)
    }

    private func syncMarketInfos() {
        tasks = Set()

        Task { [weak self] in
            await self?._syncMarketInfos()
        }.store(in: &tasks)
    }

    private func _syncMarketInfos() async {
        if case .failed = state {
            await MainActor.run { [weak self] in
                self?.internalState = .loading
            }
        }

        do {
            let marketInfos = try await marketKit.topCoinsMarketInfos(top: MarketModule.Top.top500.rawValue, currencyCode: currency.code)

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
            let marketInfos: [MarketInfo] = Array(marketInfos.prefix(top.rawValue))
            state = .loaded(marketInfos: marketInfos.sorted(sortBy: sortBy, timePeriod: timePeriod))
        case let .failed(error):
            state = .failed(error: error)
        }
    }
}

extension MarketCoinsViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var sortBys: [MarketModule.SortBy] {
        [.highestCap, .lowestCap, .gainers, .losers]
    }

    var tops: [MarketModule.Top] {
        [.top100, .top200, .top300, .top500]
    }

    var timePeriods: [HsTimePeriod] {
        [priceChangeModeManager.day1Period, .week1, .month1, .month3]
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

        syncMarketInfos()
    }

    func refresh() async {
        await _syncMarketInfos()
    }
}

extension MarketCoinsViewModel {
    enum State {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }
}
