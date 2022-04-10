import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketOverviewTopCoinsService {
    private let listCount = 5

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private var internalStatus: DataStatus<[MarketInfo]> = .loading {
        didSet {
            syncState()
        }
    }

    private let statusRelay = BehaviorRelay<DataStatus<[ListItem]>>(value: .loading)

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

        if case .failed = statusRelay.value {
            internalStatus = .loading
        }

        marketKit.marketInfosSingle(top: 1000, currencyCode: currency.code)
                .subscribe(onSuccess: { [weak self] marketInfos in
                    self?.internalStatus = .completed(marketInfos)
                }, onError: { [weak self] error in
                    self?.internalStatus = .failed(error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func syncState() {
        statusRelay.accept(internalStatus.map { marketInfos in
            listItems(marketInfos: marketInfos)
        })
    }

    private func listItems(marketInfos: [MarketInfo]) -> [ListItem] {
        let listTypes: [ListType] = [.topGainers, .topLosers]
        return listTypes.map { listType -> ListItem in
            let source = Array(marketInfos.prefix(marketTop(listType: listType).rawValue))
            let marketInfos = Array(source.sorted(sortingField: listType.sortingField, priceChangeType: priceChangeType).prefix(listCount))
            return ListItem(listType: listType, marketInfos: marketInfos)
        }
    }

    private func syncIfPossible() {
        guard case .completed = internalStatus else {
            return
        }

        syncState()
    }

}

extension MarketOverviewTopCoinsService {

    var stateObservable: Observable<DataStatus<[ListItem]>> {
        statusRelay.asObservable()
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

extension MarketOverviewTopCoinsService: IMarketListDecoratorService {

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
        if case .completed = statusRelay.value {
            statusRelay.accept(statusRelay.value)
        }
    }

}

extension MarketOverviewTopCoinsService {

    struct ListItem {
        let listType: ListType
        let marketInfos: [MarketInfo]
    }

    enum ListType: String, CaseIterable {
        case topGainers
        case topLosers
        case topCollections

        var sortingField: MarketModule.SortingField {
            switch self {
            case .topGainers: return .topGainers
            case .topLosers: return .topLosers
            case .topCollections: return .topCollections
            }
        }

        var marketField: MarketModule.MarketField {
            switch self {
            case .topGainers, .topLosers, .topCollections: return .price
            }
        }
    }

}
