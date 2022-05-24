import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketGlobalMetricService: IMarketSingleSortHeaderService {
    typealias Item = MarketInfo

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private let stateRelay = PublishRelay<MarketListServiceState<MarketInfo>>()
    private(set) var state: MarketListServiceState<MarketInfo> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }
    var sortDirectionAscending: Bool = false {
        didSet {
            syncIfPossible()
        }
    }
    var metricsType: MarketGlobalModule.MetricsType

    let initialMarketFieldIndex: Int

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, metricsType: MarketGlobalModule.MetricsType) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.metricsType = metricsType
        initialMarketFieldIndex = metricsType.marketField.rawValue

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        marketKit.marketInfosSingle(top: MarketModule.MarketTop.top100.rawValue, currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] marketInfos in
                    self?.sync(marketInfos: marketInfos)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

    private var sortingField: MarketModule.SortingField {
        switch metricsType {
        case .volume24h: return sortDirectionAscending ? .lowestVolume : .highestVolume
        default: return sortDirectionAscending ? .lowestCap : .highestCap
        }
    }

    private func sync(marketInfos: [MarketInfo], reorder: Bool = false) {
        state = .loaded(items: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case .loaded(let marketInfos, _, _) = state else {
            return
        }

        sync(marketInfos: marketInfos, reorder: true)
    }

}

extension MarketGlobalMetricService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState<MarketInfo>> {
        stateRelay.asObservable()
    }

    func refresh() {
        syncMarketInfos()
    }

}

extension MarketGlobalMetricService: IMarketListCoinUidService {

    func coinUid(index: Int) -> String? {
        guard case .loaded(let marketInfos, _, _) = state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
    }

}

extension MarketGlobalMetricService: IMarketListDecoratorService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func onUpdate(marketFieldIndex: Int) {
        if case .loaded(let marketInfos, _, _) = state {
            stateRelay.accept(.loaded(items: marketInfos, softUpdate: false, reorder: false))
        }
    }

}
