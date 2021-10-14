import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class MarketTopService: IMarketMultiSortHeaderService {
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    private let stateRelay = PublishRelay<MarketListServiceState>()
    private(set) var state: MarketListServiceState = .loading {
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

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, marketTop: MarketModule.MarketTop, sortingField: MarketModule.SortingField) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.marketTop = marketTop
        self.sortingField = sortingField

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            internalState = .loading
        }

        marketKit.marketInfosSingle(top: 1000)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] marketInfos in
                    self?.internalState = .loaded(marketInfos: marketInfos)
                }, onError: { [weak self] error in
                    self?.internalState = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = .loading
        case .loaded(let marketInfos):
            let marketInfos: [MarketInfo] = Array(marketInfos.prefix(marketTop.rawValue))
            state = .loaded(marketInfos: marketInfos.sorted(by: sortingField), softUpdate: false)
        case .failed(let error):
            state = .failed(error: error)
        }
    }

    private func syncIfPossible() {
        guard case .loaded = internalState else {
            return
        }

        syncState()
    }

}

extension MarketTopService: IMarketListService {

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

extension MarketTopService {

    private enum State {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }

}
