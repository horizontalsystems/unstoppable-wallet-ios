import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketOverviewServiceNew {
    private let listCount = 5

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let appManager: IAppManager
    private var disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private var internalState: InternalState = .loading {
        didSet {
            syncState()
        }
    }

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var marketTopMap: [ListType: MarketModule.MarketTop] = [.topGainers: .top250, .topLosers: .top250]

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, appManager: IAppManager) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.appManager = appManager

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] _ in self?.syncMarketInfos() }
        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in self?.syncMarketInfos() }

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            internalState = .loading
        }

        marketKit.marketInfosSingle(top: 1000)
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
            let items = ListType.allCases.map { listType -> Item in
                let source = Array(marketInfos.prefix(marketTop(listType: listType).rawValue))
                let marketInfos = Array(source.sorted(by: listType.sortingField).prefix(listCount))
                return Item(listType: listType, marketInfos: marketInfos)
            }

            state = .loaded(items: items)
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

extension MarketOverviewServiceNew {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func marketTop(listType: ListType) -> MarketModule.MarketTop {
        marketTopMap[listType] ?? .top250
    }

    func set(marketTop: MarketModule.MarketTop, listType: ListType) {
        marketTopMap[listType] = marketTop
        syncIfPossible()
    }

    func refresh() {
        syncMarketInfos()
    }

}

extension MarketOverviewServiceNew {

    enum InternalState {
        case loading
        case loaded(marketInfos: [MarketInfo])
        case failed(error: Error)
    }

    enum State {
        case loading
        case loaded(items: [Item])
        case failed(error: Error)
    }

    struct Item {
        let listType: ListType
        let marketInfos: [MarketInfo]
    }

    enum ListType: String, CaseIterable {
        case topGainers
        case topLosers

        var sortingField: MarketModule.SortingField {
            switch self {
            case .topGainers: return .topGainers
            case .topLosers: return .topLosers
            }
        }

        var marketField: MarketModule.MarketField {
            switch self {
            case .topGainers, .topLosers: return .price
            }
        }
    }

}
