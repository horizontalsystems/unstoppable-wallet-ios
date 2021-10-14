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

    var sortingField: MarketModule.SortingField = .highestCap {
        didSet {
            syncIfPossible()
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

        marketKit.marketInfosSingle(categoryUid: category.uid)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] marketInfos in
                    self?.sync(marketInfos: marketInfos)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func sync(marketInfos: [MarketInfo]) {
        state = .loaded(marketInfos: marketInfos.sorted(by: sortingField), softUpdate: false)
    }

    private func syncIfPossible() {
        guard case .loaded(let marketInfos, _) = state else {
            return
        }

        sync(marketInfos: marketInfos)
    }

}

extension MarketCategoryService: IMarketListService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var stateObservable: Observable<MarketListServiceState> {
        stateRelay.asObservable()
    }

    func refresh() {
        syncMarketInfos()
    }

}
