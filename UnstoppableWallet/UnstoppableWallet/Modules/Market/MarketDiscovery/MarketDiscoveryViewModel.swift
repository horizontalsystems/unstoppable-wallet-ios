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

    private var sortingField: MarketModule.SortingField
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

    var sortingFieldTitle: String {
        sortingField.title
    }

    var viewItemsDriver: Driver<[MarketModule.MarketViewItem]> {
        viewItemsRelay.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var sortingFields: [String] {
        MarketModule.SortingField.allCases.map { $0.title }
    }

    func refresh() {
        service.refresh()
    }

    func setSortingField(at index: Int) {
        sortingField = MarketModule.SortingField.allCases[index]

        syncViewItems()
    }

    func set(marketField: MarketModule.MarketField) {
        self.marketField = marketField

        syncViewItems()
    }

    func setFilter(at index: Int?) {
        guard let index = index, index < MarketDiscoveryFilter.allCases.count else {
            service.currentCategory = nil
            return
        }

        service.currentCategory = MarketDiscoveryFilter.allCases[index]
    }

    func set(preference: MarketModule.Preference) {
        sortingField = preference.sortingField
        marketField = preference.marketField

        syncViewItems()
    }

}

extension Array where Element == MarketListService.Item {

    func sort(by sortingField: MarketModule.SortingField) -> [MarketListService.Item] {
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
            case .topLosers: return item.diff < item2.diff
            }
        }
    }

}