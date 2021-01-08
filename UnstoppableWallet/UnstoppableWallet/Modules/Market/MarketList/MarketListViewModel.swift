import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketListViewModel {
    private let disposeBag = DisposeBag()

    public let service: MarketListService

    private var currentSortingField: SortingField = .highestCap

    var sortingField: String {
        currentSortingField.title
    }

    var period: String {
        service.period.title
    }

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: MarketListService) {
        self.service = service

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

    private func sorted(topItems: [MarketListDataSource.Item]) -> [MarketListDataSource.Item] {
        topItems.sorted { item, item2 in
            switch currentSortingField {
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
        let viewItems: [ViewItem] = sorted(topItems: service.items).map {
            let rateValue = CurrencyValue(currency: service.currency, value: $0.price)
            let rate = ValueFormatter.instance.format(currencyValue: rateValue) ?? ""

            return ViewItem(
                    rank: $0.rank,
                    coinName: $0.coinName,
                    coinCode: $0.coinCode,
                    rate: rate,
                    diff: $0.diff
            )
        }

        viewItemsRelay.accept(viewItems)
    }

}

extension MarketListViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    public var sortingFields: [String] {
        SortingField.allCases.map { $0.title }
    }

    public var periods: [String] {
        MarketListDataSource.Period.allCases.map { $0.title }
    }


    public func refresh() {
        service.refresh()
    }

    public func setSortingField(at index: Int) {
        currentSortingField = SortingField(rawValue: index) ?? .highestPrice

        syncViewItemsBySortingField()
    }

    public func setPeriod(at index: Int) {
        service.period = MarketListDataSource.Period(rawValue: index) ?? .day
    }

}

extension MarketListViewModel {

    struct ViewItem {
        let rank: Int
        let coinName: String
        let coinCode: String
        let rate: String
        let diff: Decimal
    }

    enum SortingField: Int, CaseIterable {
        case highestCap
        case lowestCap
        case highestVolume
        case lowestVolume
        case highestPrice
        case lowestPrice
        case topGainers
        case topLoosers

        var title: String {
            switch self {
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

