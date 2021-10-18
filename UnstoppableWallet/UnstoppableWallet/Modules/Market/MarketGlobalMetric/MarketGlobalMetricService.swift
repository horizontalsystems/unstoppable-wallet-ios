import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketGlobalMetricService: IMarketSingleSortHeaderService {
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

        marketKit.marketInfosSingle(top: MarketModule.MarketTop.top250.rawValue)
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

    private func sync(marketInfos: [MarketInfo]) {
        state = .loaded(marketInfos: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false)
    }

    private func syncIfPossible() {
        guard case .loaded(let marketInfos, _) = state else {
            return
        }

        sync(marketInfos: marketInfos)
    }

}

extension MarketGlobalMetricService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState> {
        stateRelay.asObservable()
    }

    func refresh() {
        syncMarketInfos()
    }

}

extension MarketGlobalMetricService: IMarketListDecoratorService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func resyncIfPossible() {
        if case .loaded(let marketInfos, _) = state {
            stateRelay.accept(.loaded(marketInfos: marketInfos, softUpdate: false))
        }
    }

}
