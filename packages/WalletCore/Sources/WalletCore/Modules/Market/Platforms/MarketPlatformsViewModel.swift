import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketPlatformsViewModel: ObservableObject {
    private let marketKit = Core.shared.marketKit
    private let currencyManager = Core.shared.currencyManager
    private let appManager = Core.shared.appManager
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
            stat(page: .markets, section: .platforms, event: .switchSortType(sortType: sortBy.statSortType))
            syncState()
        }
    }

    var timePeriod: HsTimePeriod = .week1 {
        didSet {
            stat(page: .markets, section: .platforms, event: .switchPeriod(period: timePeriod.statPeriod))
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
            let platforms = try await marketKit.topPlatforms(currencyCode: currency.code)

            await MainActor.run { [weak self] in
                self?.internalState = .loaded(platforms: platforms)
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
        case let .loaded(platforms):
            state = .loaded(platforms: platforms.sorted(sortBy: sortBy, timePeriod: timePeriod))
        case let .failed(error):
            state = .failed(error: error)
        }
    }
}

extension MarketPlatformsViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var sortBys: [MarketModule.SortBy] {
        [.highestCap, .lowestCap, .gainers, .losers]
    }

    var timePeriods: [HsTimePeriod] {
        [.week1, .month1, .month3]
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

extension MarketPlatformsViewModel {
    enum State {
        case loading
        case loaded(platforms: [TopPlatform])
        case failed(error: Error)
    }
}
