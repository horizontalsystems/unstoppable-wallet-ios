import Combine
import Foundation
import HsExtensions
import MarketKit

class MarketGlobalTvlMetricService {
    typealias Item = DefiCoin

    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private let apiTag: String

    private var tasks = Set<AnyTask>()
    private var cancellables = Set<AnyCancellable>()

    weak var chartService: MetricChartService? {
        didSet {
            subscribeChart()
        }
    }

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @PostPublished private(set) var state: MarketListServiceState<DefiCoin> = .loading

    var sortDirectionAscending: Bool = false {
        didSet {
            syncIfPossible(reorder: true)
        }
    }

    @PostPublished var marketPlatformField: MarketModule.MarketPlatformField = .all {
        didSet {
            syncIfPossible(reorder: true)
        }
    }

    var marketTvlField: MarketModule.MarketTvlField = .diff {
        didSet {
            syncIfPossible()
        }
    }

    private(set) var priceChangePeriod: HsPeriodType = .byPeriod(.day1) {
        didSet {
            syncIfPossible()
        }
    }

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, apiTag: String) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.apiTag = apiTag

        syncDefiCoins()
    }

    private func syncDefiCoins() {
        tasks = Set()

        if case .failed = state {
            internalState = .loading
        }

        Task { [weak self, marketKit, currency, apiTag] in
            do {
                let defiCoins = try await marketKit.defiCoins(currencyCode: currency.code, apiTag: apiTag)
                self?.internalState = .loaded(defiCoins: defiCoins)
            } catch {
                self?.internalState = .failed(error: error)
            }
        }.store(in: &tasks)
    }

    private func syncState(reorder: Bool = false) {
        switch internalState {
        case .loading:
            state = .loading
        case let .loaded(defiCoins):
            let defiCoins = defiCoins
                .filter { defiCoin in
                    switch marketPlatformField {
                    case .all: return true
                    default: return defiCoin.chains.contains(marketPlatformField.chain)
                    }
                }
                .sorted { lhsDefiCoin, rhsDefiCoin in
                    let lhsTvl = lhsDefiCoin.tvl(marketPlatformField: marketPlatformField) ?? 0
                    let rhsTvl = rhsDefiCoin.tvl(marketPlatformField: marketPlatformField) ?? 0
                    return sortDirectionAscending ? lhsTvl < rhsTvl : lhsTvl > rhsTvl
                }
            state = .loaded(items: defiCoins, softUpdate: false, reorder: reorder)
        case let .failed(error):
            state = .failed(error: error)
        }
    }

    private func syncIfPossible(reorder: Bool = false) {
        guard case .loaded = internalState else {
            return
        }

        syncState(reorder: reorder)
    }

    private func subscribeChart() {
        cancellables = Set()

        guard let chartService else {
            return
        }

        chartService.$interval
            .sink { [weak self] in self?.priceChangePeriod = $0 }
            .store(in: &cancellables)
    }
}

extension MarketGlobalTvlMetricService {
    var currency: Currency {
        currencyManager.baseCurrency
    }
}

extension MarketGlobalTvlMetricService: IMarketListService {
    var statePublisher: AnyPublisher<MarketListServiceState<Item>, Never> {
        $state
    }

    func refresh() {
        syncDefiCoins()
    }
}

extension MarketGlobalTvlMetricService: IMarketListCoinUidService {
    func coinUid(index: Int) -> String? {
        guard case let .loaded(defiCoins, _, _) = state, index < defiCoins.count else {
            return nil
        }

        switch defiCoins[index].type {
        case let .fullCoin(fullCoin): return fullCoin.coin.uid
        default: return nil
        }
    }
}

extension MarketGlobalTvlMetricService {
    private enum State {
        case loading
        case loaded(defiCoins: [DefiCoin])
        case failed(error: Error)
    }
}

extension DefiCoin {
    func tvl(marketPlatformField: MarketModule.MarketPlatformField) -> Decimal? {
        switch marketPlatformField {
        case .all: return tvl
        default: return chainTvls[marketPlatformField.chain]
        }
    }
}
