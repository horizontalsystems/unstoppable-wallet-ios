import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

class MarketOverviewTopCoinsViewModel {
    private let service: MarketOverviewTopCoinsService
    private let decorator: MarketListMarketFieldDecorator
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<DataStatus<BaseMarketOverviewTopListDataSource.ViewItem>>(value: .loading)

    init(service: MarketOverviewTopCoinsService, decorator: MarketListMarketFieldDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: DataStatus<[MarketInfo]>) {
        stateRelay.accept(state.map { viewItem(listItems: $0) })
    }

    private func viewItem(listItems: [MarketInfo]) -> BaseMarketOverviewTopListDataSource.ViewItem {
        BaseMarketOverviewTopListDataSource.ViewItem(
                rightSelectorMode: .selector,
                imageName: imageName(listType: service.listType),
                title: title(listType: service.listType),
                listViewItems: listItems.map { decorator.listViewItem(item: $0) }
        )
    }

    private func imageName(listType: MarketOverviewTopCoinsService.ListType) -> String {
        switch listType {
        case .topGainers: return "circle_up_20"
        case .topLosers: return "circle_down_20"
        }
    }

    private func title(listType: MarketOverviewTopCoinsService.ListType) -> String {
        switch listType {
        case .topGainers: return "market.top.section.header.top_gainers".localized
        case .topLosers: return "market.top.section.header.top_losers".localized
        }
    }

}

extension MarketOverviewTopCoinsViewModel: IMarketOverviewSectionViewModel {

    var stateObservable: Observable<DataStatus<()>> {
        stateRelay.map { $0.map { _ in () } }
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketOverviewTopCoinsViewModel: IBaseMarketOverviewTopListViewModel {

    var viewItem: BaseMarketOverviewTopListDataSource.ViewItem? {
        stateRelay.value.data
    }

    var selectorTitles: [String] {
        MarketModule.MarketTop.allCases.map { $0.title }
    }

    var selectorIndex: Int {
        MarketModule.MarketTop.allCases.firstIndex(of: service.marketTop) ?? 0
    }

    func onSelect(selectorIndex: Int) {
        let marketTop = MarketModule.MarketTop.allCases[selectorIndex]
        service.set(marketTop: marketTop)
    }

}

extension MarketOverviewTopCoinsViewModel: IMarketOverviewTopCoinsViewModel {

    var marketTop: MarketModule.MarketTop {
        service.marketTop
    }

    var listType: MarketOverviewTopCoinsService.ListType {
        service.listType
    }

}
