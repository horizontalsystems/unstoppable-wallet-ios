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

    private let statusRelay = BehaviorRelay<DataStatus<[MarketInfo]>>(value: .loading)

    var marketTop: MarketModule.MarketTop = .top250
    let listType: ListType

    init(listType: ListType, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, appManager: IAppManager) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.listType = listType

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

    private func listItems(marketInfos: [MarketInfo]) -> [MarketInfo] {
        let source = Array(marketInfos.prefix(marketTop.rawValue))
        return Array(source.sorted(sortingField: listType.sortingField, priceChangeType: priceChangeType).prefix(listCount))
    }

    private func syncIfPossible() {
        guard case .completed = internalStatus else {
            return
        }

        syncState()
    }

}

extension MarketOverviewTopCoinsService {

    var stateObservable: Observable<DataStatus<[MarketInfo]>> {
        statusRelay.asObservable()
    }

    func set(marketTop: MarketModule.MarketTop) {
        self.marketTop = marketTop
        syncIfPossible()
    }

    func refresh() {
        syncInternalState()
    }

}

extension MarketOverviewTopCoinsService: IMarketListDecoratorService {

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
        if case .completed = statusRelay.value {
            statusRelay.accept(statusRelay.value)
        }
    }

}

extension MarketOverviewTopCoinsService {

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
