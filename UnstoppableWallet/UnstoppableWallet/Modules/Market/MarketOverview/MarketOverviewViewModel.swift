import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketOverviewViewModel {
    private let disposeBag = DisposeBag()

    private let service: MarketListService

    private let viewItemsRelay = BehaviorRelay<[Section]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: MarketListService) {
        self.service = service

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

    private func sectionItems(by listType: MarketModule.ListType, count: Int = 3) -> Section {
        let viewItems: [MarketModule.MarketViewItem] = Array(service.items.sort(by: listType.sortingField).map { items in
            let rateValue = CurrencyValue(currency: service.currency, value: items.price)

            let marketDataValue: MarketModule.MarketDataValue
            switch listType.marketField {
            case .volume:
                marketDataValue = .volume(CurrencyCompactFormatter.instance.format(currency: service.currency, value: items.volume) ?? "n/a".localized)
            default:
                marketDataValue = .diff(items.diff)
            }

            let rate = ValueFormatter.instance.format(currencyValue: rateValue) ?? "n/a".localized

            return MarketModule.MarketViewItem(
                    rank: .index(items.rank.description),
                    coinName: items.coinName,
                    coinCode: items.coinCode,
                    coinType: items.coinType,
                    rate: rate,
                    marketDataValue: marketDataValue
            )
        }.prefix(count))

        return Section(listType: listType, viewItems: viewItems)
    }

    private func syncViewItems() {
        let sections = [
            sectionItems(by: .topGainers),
            sectionItems(by: .topLosers),
            sectionItems(by: .topVolume)
        ]

        viewItemsRelay.accept(sections)
    }

}

extension MarketOverviewViewModel {

    var viewItemsDriver: Driver<[Section]> {
        viewItemsRelay.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketOverviewViewModel {

    struct Section {
        let listType: MarketModule.ListType
        let viewItems: [MarketModule.MarketViewItem]
    }

}
