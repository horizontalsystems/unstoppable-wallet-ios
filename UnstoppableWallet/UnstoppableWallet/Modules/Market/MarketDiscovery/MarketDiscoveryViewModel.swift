import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketDiscoveryViewModel {
    private let disposeBag = DisposeBag()

    public let service: MarketDiscoveryService

    private let viewItemsRelay = BehaviorRelay<[MarketModule.MarketViewItem]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    private var sortingField: MarketListDataSource.SortingField
    private(set) var marketField: MarketModule.MarketField = .marketCap

    init(service: MarketDiscoveryService) {
        self.service = service

        sortingField = .highestCap
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: MarketDiscoveryService.State) {
        if case .loaded = state {
            syncViewItems()
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

    private func syncViewItems() {
        let viewItems: [MarketModule.MarketViewItem] = service.items.sort(by: sortingField).map {
            let marketDataValue: MarketModule.MarketDataValue
            switch marketField {
            case .price: marketDataValue = .diff($0.diff)
            case .volume:
                marketDataValue = .volume(CurrencyCompactFormatter.instance.format(currency: service.currency, value: $0.volume) ?? "-")
            case .marketCap:
                marketDataValue = .marketCap(CurrencyCompactFormatter.instance.format(currency: service.currency, value: $0.marketCap) ?? "-")
            }
            let rateValue = CurrencyValue(currency: service.currency, value: $0.price)
            let rate = ValueFormatter.instance.format(currencyValue: rateValue) ?? ""

            return MarketModule.MarketViewItem(
                    rank: .index($0.rank.description),
                    coinName: $0.coinName,
                    coinCode: $0.coinCode,
                    coinType: $0.coinType,
                    rate: rate,
                    marketDataValue: marketDataValue
            )
        }

        viewItemsRelay.accept(viewItems)
    }

}

extension MarketDiscoveryViewModel {

    public var sortingFieldTitle: String {
        sortingField.title
    }

    public var viewItemsDriver: Driver<[MarketModule.MarketViewItem]> {
        viewItemsRelay.asDriver()
    }

    public var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    public var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    public var sortingFields: [String] {
        MarketListDataSource.SortingField.allCases.map { $0.title }
    }

    public func refresh() {
        service.refresh()
    }

    public func setSortingField(at index: Int) {
        sortingField = MarketListDataSource.SortingField.allCases[index]

        syncViewItems()
    }

    public func set(marketField: MarketModule.MarketField) {
        self.marketField = marketField

        syncViewItems()
    }

    public func setFilter(at index: Int?) {
        guard let index = index, index < MarketDiscoveryFilter.allCases.count else {
            service.currentCategory = nil
            return
        }

        service.currentCategory = MarketDiscoveryFilter.allCases[index]
    }

    public func setPreferences(for type: MarketOverviewViewModel.SectionType) {
        switch type {
        case .topGainers:
            marketField = .price
            sortingField = .topGainers
        case .topLoosers:
            marketField = .price
            sortingField = .topLoosers
        case .topVolume:
            marketField = .volume
            sortingField = .highestVolume
        }

        syncViewItems()
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

extension Array where Element == MarketListService.Item {

    func sort(by sortingField: MarketListDataSource.SortingField) -> [MarketListService.Item] {
        sorted { item, item2 in
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

}