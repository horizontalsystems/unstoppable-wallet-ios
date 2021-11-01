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

    private func sync(marketInfos: [MarketInfo], reorder: Bool = false) {
        state = .loaded(marketInfos: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case .loaded(let marketInfos, _, _) = state else {
            return
        }

        sync(marketInfos: marketInfos, reorder: true)
    }

}

extension MarketCategoryService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState> {
        stateRelay.asObservable()
    }

    func refresh() {
        syncMarketInfos()
    }

}

extension MarketCategoryService: IMarketListDecoratorService {

    var initialMarketField: MarketModule.MarketField {
        .price
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func onUpdate(marketField: MarketModule.MarketField) {
        if case .loaded(let marketInfos, _, _) = state {
            stateRelay.accept(.loaded(marketInfos: marketInfos, softUpdate: false, reorder: false))
        }
    }

}
