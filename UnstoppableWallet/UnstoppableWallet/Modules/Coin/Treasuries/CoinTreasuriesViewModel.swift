import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinTreasuriesViewModel {
    private let service: CoinTreasuriesService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)
    private let scrollToTopRelay = PublishRelay<()>()

    private let dropdownValueRelay = BehaviorRelay<String>(value: "")
    private let sortDirectionAscendingRelay = BehaviorRelay<Bool>(value: false)

    init(service: CoinTreasuriesService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.typeFilterObservable) { [weak self] in self?.sync(typeFilter: $0) }
        subscribe(disposeBag, service.sortDirectionAscendingObservable) { [weak self] in self?.sync(sortDirectionAscending: $0) }

        sync(state: service.state)
        sync(typeFilter: service.typeFilter)
        sync(sortDirectionAscending: service.sortDirectionAscending)
    }

    private func sync(state: CoinTreasuriesService.State) {
        switch state {
        case .loading:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(true)
            errorRelay.accept(nil)
        case .loaded(let treasuries, let reorder):
            viewItemsRelay.accept(treasuries.map { viewItem(treasury: $0) })
            loadingRelay.accept(false)
            errorRelay.accept(nil)

            if reorder {
                scrollToTopRelay.accept(())
            }
        case .failed:
            viewItemsRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func sync(typeFilter: CoinTreasuriesService.TypeFilter) {
        dropdownValueRelay.accept(title(typeFilter: typeFilter))
    }

    private func sync(sortDirectionAscending: Bool) {
        sortDirectionAscendingRelay.accept(sortDirectionAscending)
    }

    private func viewItem(treasury: CoinTreasury) -> ViewItem {
        ViewItem(
                logoUrl: treasury.fundLogoUrl,
                fund: treasury.fund,
                country: treasury.country,
                amount: CurrencyCompactFormatter.instance.format(symbol: service.coinCode, value: treasury.amount) ?? "---",
                amountInCurrency: CurrencyCompactFormatter.instance.format(currency: service.currency, value: treasury.amountInCurrency) ?? "---"
        )
    }

    private func title(typeFilter: CoinTreasuriesService.TypeFilter) -> String {
        switch typeFilter {
        case .all: return "coin_page.treasuries.filter.all".localized
        case .public: return "coin_page.treasuries.filter.public".localized
        case .private: return "coin_page.treasuries.filter.private".localized
        case .etf: return "coin_page.treasuries.filter.etf".localized
        }
    }
}

extension CoinTreasuriesViewModel: IDropdownSortHeaderViewModel {

    var dropdownTitle: String {
        "coin_page.treasuries.filters".localized
    }

    var dropdownViewItems: [AlertViewItem] {
        CoinTreasuriesService.TypeFilter.allCases.map { typeFilter in
            AlertViewItem(text: title(typeFilter: typeFilter), selected: service.typeFilter == typeFilter)
        }
    }

    var dropdownValueDriver: Driver<String> {
        dropdownValueRelay.asDriver()
    }

    func onSelectDropdown(index: Int) {
        service.typeFilter = CoinTreasuriesService.TypeFilter.allCases[index]
    }

    var sortDirectionAscendingDriver: Driver<Bool> {
        sortDirectionAscendingRelay.asDriver()
    }

    func onToggleSortDirection() {
        service.sortDirectionAscending = !service.sortDirectionAscending
    }

}

extension CoinTreasuriesViewModel {

    var viewItemsDriver: Driver<[ViewItem]?> {
        viewItemsRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var scrollToTopSignal: Signal<()> {
        scrollToTopRelay.asSignal()
    }

    func refresh() {
        service.refresh()
    }

}

extension CoinTreasuriesViewModel {

    struct ViewItem {
        let logoUrl: String
        let fund: String
        let country: String
        let amount: String
        let amountInCurrency: String
    }

}
