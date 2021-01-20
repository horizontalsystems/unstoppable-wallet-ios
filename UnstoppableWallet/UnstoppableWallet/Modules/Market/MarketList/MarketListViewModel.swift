import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketListViewModel {
    private let disposeBag = DisposeBag()

    public let service: MarketListService

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    private var sortingField: MarketListDataSource.SortingField

    init(service: MarketListService) {
        self.service = service

        sortingField = service.sortingFields[0]
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: MarketListService.State) {
        if case .loaded = state {
            syncViewItemsBySortingField()
        }

        if case .loading = state {
            isLoadingRelay.accept(true)
        } else {
            isLoadingRelay.accept(false)
        }

        if case let .error(error: error) = state {
            errorRelay.accept(error.smartDescription)
        } else {
            errorRelay.accept(nil)
        }
    }

    private func sort(items: [MarketListService.Item], by sortingField: MarketListDataSource.SortingField) -> [MarketListService.Item] {
        items.sorted { item, item2 in
            switch sortingField {
            case .highestLiquidity: return (item.liquidity ?? 0) > (item2.liquidity ?? 0)
            case .lowestLiquidity: return (item.liquidity ?? 0) < (item2.liquidity ?? 0)
            case .highestCap: return item.marketCap > item2.marketCap
            case .lowestCap: return item.marketCap < item2.marketCap
            case .highestVolume: return item.volume > item2.volume
            case .lowestVolume: return item.volume < item2.volume
            case .highestPrice: return item.price > item2.price
            case .lowestPrice: return item.price < item2.price
            case .topGainers: return item.diff > item2.diff
            case .topLoosers: return item.diff < item2.diff
            }
        }
    }

    private func syncViewItemsBySortingField() {
        let viewItems: [ViewItem] = sort(items: service.items, by: sortingField).map {
            let rateValue = CurrencyValue(currency: service.currency, value: $0.price)
            let rate = ValueFormatter.instance.format(currencyValue: rateValue) ?? ""

            return ViewItem(
                    rank: $0.rank,
                    coinName: $0.coinName,
                    coinCode: $0.coinCode,
                    coinType: $0.coinType,
                    rate: rate,
                    diff: $0.diff
            )
        }

        viewItemsRelay.accept(viewItems)
    }

}

extension MarketListViewModel {

    public var sortingFieldTitle: String {
        sortingField.title
    }

    public var periodTitle: String {
        service.period.title
    }

    public var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    public var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    public var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    public var sortingFields: [String] {
        service.sortingFields.map { $0.title }
    }

    public var periods: [String] {
        service.periods.map { $0.title }
    }

    public func refresh() {
        service.refresh()
    }

    public func setSortingField(at index: Int) {
        sortingField = service.sortingFields[index]

        syncViewItemsBySortingField()
    }

    public func setPeriod(at index: Int) {
        service.period = service.periods[index]
    }

}

extension MarketListViewModel {

    struct ViewItem {
        let rank: Int
        let coinName: String
        let coinCode: String
        let coinType: CoinType?
        let rate: String
        let diff: Decimal
    }

}

extension MarketListDataSource.Period {

    var title: String {
        switch self {
        case .hour: return "market.top.period_1h".localized
        case .day: return "market.top.period_24h".localized
        case .dayStart: return "market.top.period_day_start".localized
        case .week: return "market.top.period_one_week".localized
        case .month: return "market.top.period_one_month".localized
        case .year: return "market.top.period_one_year".localized
        }
    }

}

extension MarketListDataSource.SortingField {

    var title: String {
        switch self {
        case .highestLiquidity: return "market.top.highest_liquidity".localized
        case .lowestLiquidity: return "market.top.lowest_liquidity".localized
        case .highestCap: return "market.top.highest_cap".localized
        case .lowestCap: return "market.top.lowest_cap".localized
        case .highestVolume: return "market.top.highest_volume".localized
        case .lowestVolume: return "market.top.lowest_volume".localized
        case .highestPrice: return "market.top.highest_price".localized
        case .lowestPrice: return "market.top.lowest_price".localized
        case .topGainers: return "market.top.top_gainers".localized
        case .topLoosers: return "market.top.top_loosers".localized
        }
    }

}
