import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketOverviewService {
    private let listCount = 5

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
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

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] _ in self?.syncInternalState() }
        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in self?.syncInternalState() }

        syncInternalState()
    }

    private func syncInternalState() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            internalState = .loading
        }

        Single.zip(
                        marketKit.marketInfosSingle(top: 1000, currencyCode: currency.code),
                        marketKit.globalMarketPointsSingle(currencyCode: currency.code, timePeriod: .day1)
                )
                .subscribe(onSuccess: { [weak self] marketInfos, globalMarketPoints in
                    self?.internalState = .loaded(marketInfos: marketInfos, globalMarketPoints: globalMarketPoints)
                }, onError: { [weak self] error in
                    self?.internalState = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = .loading
        case .loaded(let marketInfos, let globalMarketPoints):
            state = .loaded(listItems: listItems(marketInfos: marketInfos), globalMarketData: globalMarketData(globalMarketPoints: globalMarketPoints))
        case .failed(let error):
            state = .failed(error: error)
        }
    }

    private func listItems(marketInfos: [MarketInfo]) -> [ListItem] {
        ListType.allCases.map { listType -> ListItem in
            let source = Array(marketInfos.prefix(marketTop(listType: listType).rawValue))
            let marketInfos = Array(source.sorted(sortingField: listType.sortingField, priceChangeType: priceChangeType).prefix(listCount))
            return ListItem(listType: listType, marketInfos: marketInfos)
        }
    }

    private func globalMarketData(globalMarketPoints: [GlobalMarketPoint]) -> GlobalMarketData {
        let marketCapPointItems = globalMarketPoints.map { GlobalMarketPointItem(timestamp: $0.timestamp, amount: $0.marketCap) }
        let volume24hPointItems = globalMarketPoints.map { GlobalMarketPointItem(timestamp: $0.timestamp, amount: $0.volume24h) }
        let defiMarketCapPointItems = globalMarketPoints.map { GlobalMarketPointItem(timestamp: $0.timestamp, amount: $0.defiMarketCap) }
        let tvlPointItems = globalMarketPoints.map { GlobalMarketPointItem(timestamp: $0.timestamp, amount: $0.tvl) }

        return GlobalMarketData(
                marketCap: globalMarketItem(pointItems: marketCapPointItems),
                volume24h: globalMarketItem(pointItems: volume24hPointItems),
                defiMarketCap: globalMarketItem(pointItems: defiMarketCapPointItems),
                defiTvl: globalMarketItem(pointItems: tvlPointItems)
        )
    }

    private func globalMarketItem(pointItems: [GlobalMarketPointItem]) -> GlobalMarketItem {
        GlobalMarketItem(
                amount: amount(pointItems: pointItems),
                diff: diff(pointItems: pointItems),
                pointItems: pointItems
        )
    }

    private func amount(pointItems: [GlobalMarketPointItem]) -> CurrencyValue? {
        guard let lastAmount = pointItems.last?.amount else {
            return nil
        }

        return CurrencyValue(currency: currency, value: lastAmount)
    }

    private func diff(pointItems: [GlobalMarketPointItem]) -> Decimal? {
        guard let firstAmount = pointItems.first?.amount, let lastAmount = pointItems.last?.amount, firstAmount != 0 else {
            return nil
        }

        return (lastAmount - firstAmount) * 100 / firstAmount
    }

    private func syncIfPossible() {
        guard case .loaded = internalState else {
            return
        }

        syncState()
    }

}

extension MarketOverviewService {

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
        syncInternalState()
    }

}

extension MarketOverviewService: IMarketListDecoratorService {

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
        if case .loaded(let listItems, let globalMarketData) = state {
            stateRelay.accept(.loaded(listItems: listItems, globalMarketData: globalMarketData))
        }
    }

}

extension MarketOverviewService {

    enum InternalState {
        case loading
        case loaded(marketInfos: [MarketInfo], globalMarketPoints: [GlobalMarketPoint])
        case failed(error: Error)
    }

    enum State {
        case loading
        case loaded(listItems: [ListItem], globalMarketData: GlobalMarketData)
        case failed(error: Error)
    }

    struct ListItem {
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

    struct GlobalMarketData {
        let marketCap: GlobalMarketItem
        let volume24h: GlobalMarketItem
        let defiMarketCap: GlobalMarketItem
        let defiTvl: GlobalMarketItem
    }

    struct GlobalMarketItem {
        let amount: CurrencyValue?
        let diff: Decimal?
        let pointItems: [GlobalMarketPointItem]
    }

    struct GlobalMarketPointItem {
        let timestamp: TimeInterval
        let amount: Decimal
    }

}
