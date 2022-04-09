import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit
import Chart

class MarketOverviewTopCoinsViewModel {
    private let service: MarketOverviewTopCoinsService
    private let decorator: MarketListMarketFieldDecorator
    private let disposeBag = DisposeBag()

    private let statusRelay = BehaviorRelay<DataStatus<[TopViewItem]>>(value: .loading)

    init(service: MarketOverviewTopCoinsService, decorator: MarketListMarketFieldDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<[MarketOverviewTopCoinsService.ListItem]>) {
        statusRelay.accept(status.map({ listItems in
            viewItems(listItems: listItems)
        }))
    }

    private func viewItems(listItems: [MarketOverviewTopCoinsService.ListItem]) -> [TopViewItem] {
        listItems.map { item in
            TopViewItem(
                    listType: item.listType,
                    imageName: imageName(listType: item.listType),
                    title: title(listType: item.listType),
                    listViewItems: item.marketInfos.map { decorator.listViewItem(item: $0) }
            )
        }
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

extension MarketOverviewTopCoinsViewModel {

    var statusDriver: Driver<DataStatus<[TopViewItem]>> {
        statusRelay.asDriver()
    }

    var marketTops: [String] {
        MarketModule.MarketTop.allCases.map { $0.title }
    }

    func marketTop(listType: MarketOverviewTopCoinsService.ListType) -> MarketModule.MarketTop {
        service.marketTop(listType: listType)
    }

    func marketTopIndex(listType: MarketOverviewTopCoinsService.ListType) -> Int {
        let marketTop = service.marketTop(listType: listType)
        return MarketModule.MarketTop.allCases.firstIndex(of: marketTop) ?? 0
    }

    func onSelect(marketTopIndex: Int, listType: MarketOverviewTopCoinsService.ListType) {
        let marketTop = MarketModule.MarketTop.allCases[marketTopIndex]
        service.set(marketTop: marketTop, listType: listType)
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketOverviewTopCoinsViewModel {

    struct TopViewItem {
        let listType: MarketOverviewTopCoinsService.ListType
        let imageName: String
        let title: String
        let listViewItems: [MarketModule.ListViewItem]
    }

}
