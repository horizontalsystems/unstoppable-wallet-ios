import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketWatchlistViewModel {
    private let disposeBag = DisposeBag()

    public let service: MarketListService

    private let viewItemsRelay = BehaviorRelay<[MarketModule.MarketViewItem]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    private var sortingField: MarketModule.SortingField
    private(set) var marketField: MarketModule.MarketField = .marketCap

    init(service: MarketListService) {
        self.service = service

        sortingField = MarketModule.SortingField.allCases[0]
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: MarketListService.State) {
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
                    score: nil,
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

extension MarketWatchlistViewModel {

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
        MarketModule.SortingField.allCases.map { $0.title }
    }

    public func refresh() {
        service.refresh()
    }

    public func setSortingField(at index: Int) {
        sortingField = MarketModule.SortingField.allCases[index]

        syncViewItems()
    }

    public func set(marketField: MarketModule.MarketField) {
        self.marketField = marketField

        syncViewItems()
    }

}
