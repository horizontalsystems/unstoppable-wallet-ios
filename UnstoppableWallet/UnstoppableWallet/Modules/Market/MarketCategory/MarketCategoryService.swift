import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketCategoryService: IMarketMultiSortHeaderService {
    let category: CoinCategory
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

    private let sortingFieldRelay = PublishRelay<MarketModule.SortingField>()
    var sortingField: MarketModule.SortingField = .highestCap {
        didSet {
            sortingFieldRelay.accept(sortingField)
        }
    }

    private let marketFieldRelay = PublishRelay<MarketModule.MarketField>()
    var marketField: MarketModule.MarketField = .price {
        didSet {
            marketFieldRelay.accept(marketField)
        }
    }

    init?(categoryUid: String, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        guard let category = try? marketKit.coinCategory(uid: categoryUid) else {
            return nil
        }

        self.category = category
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        marketKit.marketInfosSingle(coinUids: ["bitcoin", "ethereum", "tether", "uniswap"])
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] marketInfos in
                    self?.state = .loaded(marketInfos: marketInfos)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

}

extension MarketCategoryService: IMarketListService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var stateObservable: Observable<MarketListServiceState> {
        stateRelay.asObservable()
    }

    var sortingFieldObservable: Observable<MarketModule.SortingField> {
        sortingFieldRelay.asObservable()
    }

    var marketFieldObservable: Observable<MarketModule.MarketField> {
        marketFieldRelay.asObservable()
    }

    func refresh() {
        syncMarketInfos()
    }

}
