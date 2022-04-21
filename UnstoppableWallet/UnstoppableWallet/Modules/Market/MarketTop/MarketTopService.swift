import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketTopService: IMarketMultiSortHeaderService {
    typealias Item = MarketInfo

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    private let stateRelay = PublishRelay<MarketListServiceState<MarketInfo>>()
    private(set) var state: MarketListServiceState<MarketInfo> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    var marketTop: MarketModule.MarketTop {
        didSet {
            syncIfPossible()
        }
    }

    var sortingField: MarketModule.SortingField {
        didSet {
            syncIfPossible()
        }
    }

    let initialMarketFieldIndex: Int

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, marketTop: MarketModule.MarketTop, sortingField: MarketModule.SortingField, marketField: MarketModule.MarketField) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.marketTop = marketTop
        self.sortingField = sortingField
        initialMarketFieldIndex = marketField.rawValue

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            internalState = .loading
        }

        marketKit.marketInfosSingle(top: 1000, currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] marketInfos in
                    self?.internalState = .loaded(marketInfos: marketInfos)
                }, onError: { [weak self] error in
                    self?.internalState = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func syncState(reorder: Bool = false) {
        switch internalState {
        case .loading:
            state = .loading
        case .loaded(let marketInfos):
            let marketInfos: [MarketInfo] = Array(marketInfos.prefix(marketTop.rawValue))
            state = .loaded(items: marketInfos.sorted(sortingField: sortingField, priceChangeType: priceChangeType), softUpdate: false, reorder: reorder)
        case .failed(let error):
            state = .failed(error: error)
        }
    }

    private func syncIfPossible() {
        guard case .loaded = internalState else {
            return
        }

        syncState(reorder: true)
    }

}

extension MarketTopService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState<MarketInfo>> {
        stateRelay.asObservable()
    }

    func refresh() {
        syncMarketInfos()
    }

}

extension MarketTopService: IMarketListCoinUidService {

    func coinUid(index: Int) -> String? {
        guard case .loaded(let marketInfos, _, _) = state, index < marketInfos.count else {
            return nil
        }

        return marketInfos[index].fullCoin.coin.uid
    }

}

extension MarketTopService: IMarketListDecoratorService {

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

extension MarketTopService {

    private enum State {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }

}
