import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketOverviewTopCoinsService {
    private let baseService: MarketOverviewService
    private let disposeBag = DisposeBag()

    private(set) var marketTop: MarketModule.MarketTop = .top100
    let listType: ListType

    private let marketInfosRelay = PublishRelay<[MarketInfo]?>()
    private(set) var marketInfos: [MarketInfo]? {
        didSet {
            marketInfosRelay.accept(marketInfos)
        }
    }

    init(listType: ListType, baseService: MarketOverviewService) {
        self.listType = listType
        self.baseService = baseService

        subscribe(disposeBag, baseService.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: baseService.state)
    }

    private func sync(state: DataStatus<MarketOverviewService.Item>) {
        marketInfos = state.data.map { item in
            switch listType {
            case .topGainers:
                switch marketTop {
                case .top100: return item.topMovers.gainers100
                case .top200: return item.topMovers.gainers200
                case .top300: return item.topMovers.gainers300
                }
            case .topLosers:
                switch marketTop {
                case .top100: return item.topMovers.losers100
                case .top200: return item.topMovers.losers200
                case .top300: return item.topMovers.losers300
                }
            }
        }
    }

}

extension MarketOverviewTopCoinsService {

    var marketInfosObservable: Observable<[MarketInfo]?> {
        marketInfosRelay.asObservable()
    }

    func set(marketTop: MarketModule.MarketTop) {
        self.marketTop = marketTop
        sync(state: baseService.state)
    }

}

extension MarketOverviewTopCoinsService: IMarketListDecoratorService {

    var initialMarketFieldIndex: Int {
        0
    }

    var currency: Currency {
        baseService.currency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func onUpdate(marketFieldIndex: Int) {
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
