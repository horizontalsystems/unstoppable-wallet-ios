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

    private let statusRelay = BehaviorRelay<DataStatus<ViewItem>>(value: .loading)

    init(service: MarketOverviewTopCoinsService, decorator: MarketListMarketFieldDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(status: $0) }
    }

    private func sync(status: DataStatus<MarketOverviewTopCoinsService.State>) {
        statusRelay.accept(status.map({ state in
            viewItem(listItems: state.listItems, globalMarketData: state.globalMarketData)
        }))
    }

    private func viewItem(listItems: [MarketOverviewTopCoinsService.ListItem], globalMarketData: MarketOverviewTopCoinsService.GlobalMarketData) -> ViewItem {
        ViewItem(
                globalMarketViewItem: globalMarketViewItem(globalMarketData: globalMarketData),
                topViewItems: listItems.map { topViewItem(item: $0) }
        )
    }

    private func globalMarketViewItem(globalMarketData: MarketOverviewTopCoinsService.GlobalMarketData) -> GlobalMarketViewItem {
        GlobalMarketViewItem(
                totalMarketCap: chartViewItem(item: globalMarketData.marketCap),
                volume24h: chartViewItem(item: globalMarketData.volume24h),
                defiCap: chartViewItem(item: globalMarketData.defiMarketCap),
                defiTvl: chartViewItem(item: globalMarketData.defiTvl)
        )
    }

    private func chartViewItem(item: MarketOverviewTopCoinsService.GlobalMarketItem) -> ChartViewItem {
        let value = item.amount.flatMap { CurrencyCompactFormatter.instance.format(currency: $0.currency, value: $0.value) }

        var chartData: ChartData?
        var trend: MovementTrend = .neutral

        let pointItems = item.pointItems

        if let firstPointItem = pointItems.first, let lastPointItem = pointItems.last {
            let chartItems: [ChartItem] = pointItems.map {
                let item = ChartItem(timestamp: $0.timestamp)
                item.added(name: .rate, value: $0.amount)
                return item
            }

            if firstPointItem.amount > lastPointItem.amount {
                trend = .down
            } else if firstPointItem.amount < lastPointItem.amount {
                trend = .up
            }

            chartData = ChartData(
                    items: chartItems,
                    startTimestamp: firstPointItem.timestamp,
                    endTimestamp: lastPointItem.timestamp
            )
        }

        return ChartViewItem(
                value: value,
                diff: item.diff,
                chartData: chartData,
                chartTrend: trend
        )
    }

    private func topViewItem(item: MarketOverviewTopCoinsService.ListItem) -> TopViewItem {
        TopViewItem(
                listType: item.listType,
                imageName: imageName(listType: item.listType),
                title: title(listType: item.listType),
                listViewItems: item.marketInfos.map { decorator.listViewItem(item: $0) }
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

extension MarketOverviewTopCoinsViewModel {

    var statusDriver: Driver<DataStatus<ViewItem>> {
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

    struct ViewItem {
        let globalMarketViewItem: GlobalMarketViewItem
        let topViewItems: [TopViewItem]
    }

    struct GlobalMarketViewItem {
        let totalMarketCap: ChartViewItem
        let volume24h: ChartViewItem
        let defiCap: ChartViewItem
        let defiTvl: ChartViewItem
    }

    struct ChartViewItem {
        let value: String?
        let diff: Decimal?
        let chartData: ChartData?
        let chartTrend: MovementTrend
    }

    struct TopViewItem {
        let listType: MarketOverviewTopCoinsService.ListType
        let imageName: String
        let title: String
        let listViewItems: [MarketModule.ListViewItem]
    }

}
