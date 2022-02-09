import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketGlobalTvlMetricService {
    typealias Item = DefiCoin

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var syncDisposeBag = DisposeBag()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    private let stateRelay = PublishRelay<MarketListServiceState<DefiCoin>>()
    private(set) var state: MarketListServiceState<DefiCoin> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    var sortDirectionAscending: Bool = false {
        didSet {
            syncIfPossible(reorder: true)
        }
    }

    private let marketPlatformRelay = PublishRelay<MarketModule.MarketPlatformField>()
    var marketPlatformField: MarketModule.MarketPlatformField = .all {
        didSet {
            marketPlatformRelay.accept(marketPlatformField)
            syncIfPossible(reorder: true)
        }
    }

    var marketTvlField: MarketModule.MarketTvlField = .diff {
        didSet {
            syncIfPossible()
        }
    }

    private(set) var priceChangePeriod: HsTimePeriod = .day1 {
        didSet {
            syncIfPossible()
        }
    }

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        syncDefiCoins()
    }

    private func syncDefiCoins() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            internalState = .loading
        }

        marketKit.defiCoinsSingle(currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] defiCoins in
                    self?.internalState = .loaded(defiCoins: defiCoins)
                }, onError: { [weak self] error in
                    self?.internalState = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func syncState(reorder: Bool = false) {
        switch internalState {
        case .loading:
            state = .loading
        case .loaded(let defiCoins):
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
        case .failed(let error):
            state = .failed(error: error)
        }
    }

    private func syncIfPossible(reorder: Bool = false) {
        guard case .loaded = internalState else {
            return
        }

        syncState(reorder: reorder)
    }

}

extension MarketGlobalTvlMetricService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    func setPriceChange(index: Int) {
        let tvlChartCompatiblePeriods: [HsTimePeriod] = [.day1, .week1, .week2, .month1, .month3, .month6, .year1]
        if index < tvlChartCompatiblePeriods.count {
            priceChangePeriod = tvlChartCompatiblePeriods[index]
        } else {
            priceChangePeriod = tvlChartCompatiblePeriods[0]
        }
    }

}

extension MarketGlobalTvlMetricService {

    var marketPlatformObservable: Observable<MarketModule.MarketPlatformField> {
        marketPlatformRelay.asObservable()
    }

}

extension MarketGlobalTvlMetricService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState<DefiCoin>> {
        stateRelay.asObservable()
    }

    func refresh() {
        syncDefiCoins()
    }

}

extension MarketGlobalTvlMetricService: IMarketListCoinUidService {

    func coinUid(index: Int) -> String? {
        guard case .loaded(let defiCoins, _, _) = state, index < defiCoins.count else {
            return nil
        }

        switch defiCoins[index].type {
        case .fullCoin(let fullCoin): return fullCoin.coin.uid
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
