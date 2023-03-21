import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

protocol IMarketFilteredListProvider {
    func marketInfoSingle(currencyCode: String) -> Single<[MarketInfo]>
}

class MarketFilteredListService: IMarketMultiSortHeaderService {
    private let currencyKit: CurrencyKit.Kit
    private let provider: IMarketFilteredListProvider
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

    init(currencyKit: CurrencyKit.Kit, provider: IMarketFilteredListProvider) {
        self.currencyKit = currencyKit
        self.provider = provider

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        provider.marketInfoSingle(currencyCode: currency.code)
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

extension MarketFilteredListService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState<MarketInfo>> {
        stateRelay.asObservable()
    }

    func refresh() {
        syncMarketInfos()
    }

}

extension MarketFilteredListService: IMarketListCoinUidService {

    func coinUid(index: Int) -> String? {
        guard case .loaded(let marketInfos, _, _) = state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
    }

}

extension MarketFilteredListService: IMarketListDecoratorService {

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
