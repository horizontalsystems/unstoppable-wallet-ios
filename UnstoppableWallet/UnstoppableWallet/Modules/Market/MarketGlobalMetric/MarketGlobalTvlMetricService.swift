import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketGlobalTvlMetricService {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private let stateRelay = PublishRelay<MarketListServiceState>()
    private(set) var state: MarketListServiceState = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }
    var sortDirectionAscending: Bool = false {
        didSet {
            syncIfPossible(reorder: true)
        }
    }

    var marketPlatformField: MarketModule.MarketPlatformField = .all {
        didSet {
            syncIfPossible()
        }
    }

    var marketTvlField: MarketModule.MarketTvlField = .diff {
        didSet {
            syncIfPossible()
        }
    }

    private(set) var marketTvlPriceChangeField: MarketModule.PriceChangeType = .day {
        didSet {
            syncIfPossible()
        }
    }

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        marketKit.marketInfosSingle(top: MarketModule.MarketTop.top250.rawValue, currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] marketInfos in
                    self?.sync(marketInfos: marketInfos)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

    private var sortingField: MarketModule.SortingField {
        sortDirectionAscending ? .lowestCap : .highestCap
    }

    private func sync(marketInfos: [MarketInfo], reorder: Bool = false) {
        state = .loaded(marketInfos: marketInfos.sorted(sortingField: sortingField, priceChangeType: marketTvlPriceChangeField), softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible(reorder: Bool = false) {
        guard case .loaded(let marketInfos, _, _) = state else {
            return
        }

        sync(marketInfos: marketInfos, reorder: reorder)
    }

}

extension MarketGlobalTvlMetricService: IMarketListService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    func setPriceChange(index: Int) {
        let tvlChartCompatibleFields: [MarketModule.PriceChangeType] = [.day, .week, .month]
        if index < tvlChartCompatibleFields.count {
            marketTvlPriceChangeField = tvlChartCompatibleFields[index]
        } else {
            marketTvlPriceChangeField = tvlChartCompatibleFields[0]
        }
    }

    var stateObservable: Observable<MarketListServiceState> {
        stateRelay.asObservable()
    }

    func refresh() {
        syncMarketInfos()
    }

}
