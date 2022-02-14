import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import LanguageKit

class MarketCategoryService: IMarketMultiSortHeaderService {
    typealias Item = MarketInfo

    let category: CoinCategory
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let languageManager: LanguageManager
    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private let stateRelay = PublishRelay<MarketListServiceState<MarketInfo>>()
    private(set) var state: MarketListServiceState<MarketInfo> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    var sortingField: MarketModule.SortingField = .highestCap {
        didSet {
            syncIfPossible()
        }
    }

    init?(categoryUid: String, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, languageManager: LanguageManager) {
        guard let category = try? marketKit.coinCategory(uid: categoryUid) else {
            return nil
        }

        self.category = category
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.languageManager = languageManager

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        marketKit.marketInfosSingle(categoryUid: category.uid, currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] marketInfos in
                    self?.sync(marketInfos: marketInfos)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
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

extension MarketCategoryService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState<MarketInfo>> {
        stateRelay.asObservable()
    }

    var categoryDescription: String? {
        category.descriptions[languageManager.currentLanguage] ?? category.descriptions.first?.value
    }

    func refresh() {
        syncMarketInfos()
    }

}

extension MarketCategoryService: IMarketListCoinUidService {

    func coinUid(index: Int) -> String? {
        guard case .loaded(let marketInfos, _, _) = state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
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
            stateRelay.accept(.loaded(items: marketInfos, softUpdate: false, reorder: false))
        }
    }

}
