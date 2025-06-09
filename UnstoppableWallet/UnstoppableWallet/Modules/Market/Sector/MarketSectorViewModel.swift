import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketSectorViewModel: ObservableObject {
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager
    private let priceChangeModeManager = App.shared.priceChangeModeManager

    let sector: CoinCategory

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
            stat(page: .topPlatform, event: .switchSortType(sortType: sortBy.statSortType))
            syncState()
        }
    }

    var timePeriod: HsTimePeriod {
        didSet {
            stat(page: .markets, section: .platforms, event: .switchPeriod(period: timePeriod.statPeriod))
            syncState()
        }
    }

    init(sector: CoinCategory) {
        self.sector = sector
        timePeriod = priceChangeModeManager.day1Period

        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.sync()
            }
            .store(in: &cancellables)

        priceChangeModeManager.$priceChangeMode
            .sink { [weak self] _ in
                self?.syncPeriod()
            }
            .store(in: &cancellables)

        sync()
    }

    private func syncPeriod() {
        timePeriod = priceChangeModeManager.convert(period: timePeriod)
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = .loading
        case let .loaded(marketInfos):
            state = .loaded(marketInfos: marketInfos.sorted(sortBy: sortBy, timePeriod: timePeriod))
        case let .failed(error):
            state = .failed(error: error)
        }
    }
}

extension MarketSectorViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var sortBys: [MarketModule.SortBy] {
        [.highestCap, .lowestCap, .gainers, .losers]
    }

    var timePeriods: [HsTimePeriod] {
        [priceChangeModeManager.day1Period, .week1, .month1, .month3]
    }

    var sectorDesctiprion: String {
        sector.descriptions[currency.code] ??
            sector.descriptions[LanguageManager.fallbackLanguage] ?? ""
    }

    func sync() {
        tasks = Set()

        if case .failed = internalState {
            internalState = .loading
        }

        let sector = sector

        Task { [weak self, marketKit, currency] in
            do {
                let marketInfos = try await marketKit.marketInfos(categoryUid: sector.uid, currencyCode: currency.code)

                await MainActor.run { [weak self] in
                    self?.internalState = .loaded(marketInfos: marketInfos)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.internalState = .failed(error: error)
                }
            }
        }
        .store(in: &tasks)
    }
}

extension MarketSectorViewModel {
    enum State {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }
}
