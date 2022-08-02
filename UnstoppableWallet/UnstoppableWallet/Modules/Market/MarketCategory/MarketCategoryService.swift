import RxSwift
import RxRelay
import MarketKit
import CurrencyKit
import LanguageKit

protocol IMarketMetricsServiceConfigProvider {
    var marketInfoSingle: Single<[MarketInfo]> { get }
    var name: String { get }
    var categoryDescription: String? { get }
    var imageUrl: String { get }
    var imageMode: MarketCategoryViewModel.ViewItem.ImageMode { get }
}

class MarketCategoryService: IMarketMultiSortHeaderService {
    typealias Item = MarketInfo

    private let currencyKit: CurrencyKit.Kit
    private let configProvider: IMarketMetricsServiceConfigProvider
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

    init(currencyKit: CurrencyKit.Kit, configProvider: IMarketMetricsServiceConfigProvider) {
        self.currencyKit = currencyKit
        self.configProvider = configProvider

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        configProvider.marketInfoSingle
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

extension MarketCategoryService {

    var name: String {
         configProvider.name
    }

    var categoryDescription: String? {
        configProvider.categoryDescription
    }

    var imageUrl: String {
        configProvider.imageUrl
    }

    var imageMode: MarketCategoryViewModel.ViewItem.ImageMode {
        configProvider.imageMode
    }

}

extension MarketCategoryService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState<MarketInfo>> {
        stateRelay.asObservable()
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

    var initialMarketFieldIndex: Int {
        0
    }

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
