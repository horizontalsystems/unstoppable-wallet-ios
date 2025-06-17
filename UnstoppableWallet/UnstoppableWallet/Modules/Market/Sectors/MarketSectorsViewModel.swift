import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketSectorsViewModel: ObservableObject {
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
            stat(page: .markets, section: .sectors, event: .switchSortType(sortType: sortBy.statSortType))
            syncState()
        }
    }

    var timePeriod: HsTimePeriod = .day1 {
        didSet {
            stat(page: .markets, section: .sectors, event: .switchPeriod(period: timePeriod.statPeriod))
            syncState()
        }
    }

    private func sync() {
        tasks = Set()

        Task { [weak self] in
            await self?._sync()
        }
        .store(in: &tasks)
    }

    private func _sync() async {
        if case .failed = state {
            await MainActor.run { [weak self] in
                self?.internalState = .loading
            }
        }

        do {
            let sectors = try await marketKit.coinCategories(currencyCode: currencyManager.baseCurrency.code, withTopCoins: true)
            let coinSectorsWithTopCoins = sectors.map {
                guard let topCoins = $0.topCoins else {
                    return CoinSectorWithTopCoins(sector: $0, topCoins: [])
                }

                let coins = (try? marketKit.fullCoins(coinUids: topCoins)) ?? []
                return .init(sector: $0, topCoins: coins.map(\.coin))
            }

            await MainActor.run { [weak self] in
                self?.internalState = .loaded(sectors: coinSectorsWithTopCoins)
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
        case let .loaded(sectors):
            state = .loaded(sectors: sectors.sorted(sortBy: sortBy, timePeriod: timePeriod))
        case let .failed(error):
            state = .failed(error: error)
        }
    }
}

extension MarketSectorsViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var sortBys: [MarketModule.SortBy] {
        [.highestCap, .lowestCap, .gainers, .losers]
    }

    var timePeriods: [HsTimePeriod] {
        [.day1, .week1, .month1]
    }

    func load() {
        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.sync()
            }
            .store(in: &cancellables)

        appManager.willEnterForegroundPublisher
            .sink { [weak self] in self?.sync() }
            .store(in: &cancellables)

        sync()
    }

    func refresh() async {
        await _sync()
    }
}

extension MarketSectorsViewModel {
    enum State {
        case loading
        case loaded(sectors: [CoinSectorWithTopCoins])
        case failed(error: Error)
    }

    struct CoinSectorWithTopCoins {
        let sector: CoinCategory
        let topCoins: [Coin]
    }
}

extension MarketSectorsViewModel.CoinSectorWithTopCoins: Hashable, Equatable {
    func priceChangeValue(timePeriod: HsTimePeriod) -> Decimal? {
        switch timePeriod {
        case .day1: return sector.diff24H
        case .week1: return sector.diff1W
        case .month1: return sector.diff1M
        default: return nil
        }
    }

    public static func == (lhs: MarketSectorsViewModel.CoinSectorWithTopCoins, rhs: MarketSectorsViewModel.CoinSectorWithTopCoins) -> Bool {
        lhs.sector.uid == rhs.sector.uid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sector.uid)
    }
}

extension [MarketSectorsViewModel.CoinSectorWithTopCoins] {
    func sorted(sortBy: MarketModule.SortBy, timePeriod: HsTimePeriod) -> [MarketSectorsViewModel.CoinSectorWithTopCoins] {
        switch sortBy {
        case .highestVolume, .lowestVolume: return self
        case .highestCap: return sorted { $0.sector.marketCap ?? 0 > $1.sector.marketCap ?? 0 }
        case .lowestCap: return sorted { $0.sector.marketCap ?? 0 < $1.sector.marketCap ?? 0 }
        case .gainers, .losers: return sorted {
                guard let lhsPriceChange = $0.priceChangeValue(timePeriod: timePeriod) else {
                    return false
                }
                guard let rhsPriceChange = $1.priceChangeValue(timePeriod: timePeriod) else {
                    return true
                }

                return sortBy == .gainers ? lhsPriceChange > rhsPriceChange : lhsPriceChange < rhsPriceChange
            }
        }
    }
}
