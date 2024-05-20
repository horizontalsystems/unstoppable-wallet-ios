import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketCoinsViewModel: ObservableObject {
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager

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
            syncState()
        }
    }

    var top: MarketModule.Top = .top100 {
        didSet {
            syncState()
        }
    }

    var timePeriod: HsTimePeriod = .day1 {
        didSet {
            syncState()
        }
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
        [.day1, .week1, .month1, .month3]
    }

    func load() {
        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.syncMarketInfos()
            }
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
