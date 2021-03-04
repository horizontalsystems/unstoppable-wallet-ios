import Foundation
import RxSwift
import RxCocoa
import CoinKit

class MarketAdvancedSearchViewModel {
    private let disposeBag = DisposeBag()

    let service: MarketAdvancedSearchService

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    private let showErrorRelay = PublishRelay<String>()
    private let itemCountRelay = BehaviorRelay<Int?>(value: nil)
    private let showResultEnabledRelay = BehaviorRelay<Bool>(value: false)

    init(service: MarketAdvancedSearchService) {
        self.service = service

        subscribe(disposeBag, service.stateUpdatedObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.filterUpdatedObservable) { [weak self] in self?.syncFilters() }

        syncFilters()
        sync(state: service.state)
    }

    private func sync(state: MarketAdvancedSearchService.State) {
        switch state {
        case .loading:
            showResultEnabledRelay.accept(false)
            itemCountRelay.accept(nil)
        case .loaded(let count):
            showResultEnabledRelay.accept(count > 0)
            itemCountRelay.accept(count)
        case .failed(let error):
            showResultEnabledRelay.accept(false)
            itemCountRelay.accept(nil)

            showErrorRelay.accept(error.convertedError.smartDescription)
        }
    }

    private func syncFilters() {
        let viewItems = [
            ViewItem(
                filter: .coinList,
                value: service.coinListCount.title,
                valueColor: .normal),
            ViewItem(
                filter: .marketCap,
                value: service.marketCap.title,
                valueColor: service.marketCap.valueColor),
            ViewItem(
                filter: .volume,
                value: service.volume.title,
                valueColor: service.volume.valueColor),
            ViewItem(
                filter: .liquidity,
                value: service.liquidity.title,
                valueColor: service.liquidity.valueColor),
            ViewItem(
                filter: .period,
                value: service.period.title,
                valueColor: service.period.valueColor),
            ViewItem(
                filter: .priceChange,
                value: service.priceChange.title,
                valueColor: service.priceChange.valueColor)
        ]

        viewItemsRelay.accept(viewItems)
    }

    private func wrappedViewItems<T: IWrappedFilterViewItem>(list: [T], selected: T) -> [FilterViewItem] {
        list.map { FilterViewItem(title: $0.title, color: $0.valueColor, selected: selected == $0) }
    }

}

extension MarketAdvancedSearchViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var showErrorSignal: Signal<String> {
        showErrorRelay.asSignal()
    }

    var itemCountDriver: Driver<Int?> {
        itemCountRelay.asDriver()
    }

    var showResultEnabledDriver: Driver<Bool> {
        showResultEnabledRelay.asDriver()
    }

    func viewItems(filter: Filter) -> [FilterViewItem] {
        switch filter {
        case .coinList: return wrappedViewItems(list: MarketAdvancedSearchService.CoinListCount.allCases, selected: service.coinListCount)
        case .volume: return wrappedViewItems(list: MarketAdvancedSearchService.ValueFilter.allCases, selected: service.volume)
        case .marketCap: return wrappedViewItems(list: MarketAdvancedSearchService.ValueFilter.allCases, selected: service.marketCap)
        case .liquidity: return wrappedViewItems(list: MarketAdvancedSearchService.ValueFilter.allCases, selected: service.liquidity)
        case .priceChange: return wrappedViewItems(list: MarketAdvancedSearchService.PriceChangeFilter.allCases, selected: service.priceChange)
        case .period: return wrappedViewItems(list: MarketAdvancedSearchService.PricePeriodFilter.allCases, selected: service.period)
        }
    }

    func setField(at index: Int, filter: Filter) {
        switch filter {
        case .coinList: service.coinListCount = MarketAdvancedSearchService.CoinListCount.allCases[index]
        case .volume: service.volume = MarketAdvancedSearchService.ValueFilter.allCases[index]
        case .marketCap: service.marketCap = MarketAdvancedSearchService.ValueFilter.allCases[index]
        case .liquidity: service.liquidity = MarketAdvancedSearchService.ValueFilter.allCases[index]
        case .priceChange: service.priceChange = MarketAdvancedSearchService.PriceChangeFilter.allCases[index]
        case .period: service.period = MarketAdvancedSearchService.PricePeriodFilter.allCases[index]
        }
    }

    func resetAll() {
        service.coinListCount = .top250
        service.period = .day
        service.volume = .none
        service.marketCap = .none
        service.liquidity = .none
        service.priceChange = .none
    }

}

extension MarketAdvancedSearchViewModel {

    enum Filter: String, CaseIterable {
        case coinList = "market.advanced_search.coin_list"
        case marketCap = "market.advanced_search.market_cap"
        case volume = "market.advanced_search.volume"
        case liquidity = "market.advanced_search.liquidity"
        case period = "market.advanced_search.period"
        case priceChange = "market.advanced_search.price_change"

        var title: String { self.rawValue.localized }
    }

    struct FilterViewItem {
        let title: String
        let color: ValueColor
        let selected: Bool
    }

    enum ValueColor {
        case normal
        case positive
        case negative
        case none
    }

    struct ViewItem {
        let filter: Filter
        let value: String
        let valueColor: ValueColor
    }

    enum State {
        case loading
        case loaded(Int)
        case error(String)
    }

}


private protocol IWrappedFilterViewItem: Equatable {
    var title: String { get }
    var valueColor: MarketAdvancedSearchViewModel.ValueColor { get }
}

extension MarketAdvancedSearchService.CoinListCount: IWrappedFilterViewItem {

    var title: String {
        "market.advanced_search.top".localized(self.rawValue)
    }

    var valueColor: MarketAdvancedSearchViewModel.ValueColor { .normal }

}

extension MarketAdvancedSearchService.ValueFilter: IWrappedFilterViewItem {

    var title: String {
        switch self {
        case .none: return "market.advanced_search.none".localized
        case .lessM5: return "market.advanced_search.less_5_m".localized
        case .m5m10: return "market.advanced_search.m_5_m_10".localized
        case .m20m100: return "market.advanced_search.m_20_m_100".localized
        case .m100b1: return "market.advanced_search.m_100_b_1".localized
        case .b1b5: return "market.advanced_search.b_1_b_5".localized
        case .moreB5: return "market.advanced_search.more_5_b".localized
        }
    }

    var valueColor: MarketAdvancedSearchViewModel.ValueColor {
        self == .none ? .none : .normal
    }

}

extension MarketAdvancedSearchService.PriceChangeFilter: IWrappedFilterViewItem {

    var title: String {
        switch self {
        case .none: return "market.advanced_search.none".localized
        case .plus10: return "> +10 %"
        case .plus25: return "> +25 %"
        case .plus50: return "> +50 %"
        case .plus100: return "> +100 %"
        case .minus10: return "> -10 %"
        case .minus25: return "> -25 %"
        case .minus50: return "> -50 %"
        case .minus100: return "> -100 %"
        }
    }

    var valueColor: MarketAdvancedSearchViewModel.ValueColor {
        switch self {
        case .none: return .none
        case .plus10, .plus25, .plus50, .plus100: return .positive
        case .minus10, .minus25, .minus50, .minus100: return .negative
        }
    }

}

extension MarketAdvancedSearchService.PricePeriodFilter: IWrappedFilterViewItem {

    var title: String {
        switch self {
        case .day: return "market.advanced_search.day".localized
        case .week: return "market.advanced_search.week".localized
        case .month: return "market.advanced_search.month".localized
        case .month3: return "market.advanced_search.month3".localized
        case .month6: return "market.advanced_search.month6".localized
        case .year: return "market.advanced_search.year".localized
        }
    }

    var valueColor: MarketAdvancedSearchViewModel.ValueColor {
        self == .none ? .none : .normal
    }

}

