import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit
import Chart

class MarketOverviewViewModel {
    private let service: MarketOverviewService
    private let decorator: MarketListMarketFieldDecorator
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: MarketOverviewService, decorator: MarketListMarketFieldDecorator) {
        self.service = service
        self.decorator = decorator

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: MarketOverviewService.State) {
        switch state {
        case .loading:
            viewItemRelay.accept(nil)
            loadingRelay.accept(true)
            errorRelay.accept(nil)
        case .loaded(let listItems, let globalMarketData):
            viewItemRelay.accept(viewItem(listItems: listItems, globalMarketData: globalMarketData))
            loadingRelay.accept(false)
            errorRelay.accept(nil)
        case .failed:
            viewItemRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

    private func viewItem(listItems: [MarketOverviewService.ListItem], globalMarketData: MarketOverviewService.GlobalMarketData) -> ViewItem {
        ViewItem(
                globalMarketViewItem: globalMarketViewItem(globalMarketData: globalMarketData),
                topViewItems: listItems.map { topViewItem(item: $0) }
        )
    }

    private func globalMarketViewItem(globalMarketData: MarketOverviewService.GlobalMarketData) -> GlobalMarketViewItem {
        GlobalMarketViewItem(
                totalMarketCap: chartViewItem(item: globalMarketData.marketCap),
                volume24h: chartViewItem(item: globalMarketData.volume24h),
                defiCap: chartViewItem(item: globalMarketData.defiMarketCap),
                defiTvl: chartViewItem(item: globalMarketData.defiTvl)
        )
    }

    private func chartViewItem(item: MarketOverviewService.GlobalMarketItem) -> ChartViewItem {
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

    private func topViewItem(item: MarketOverviewService.ListItem) -> TopViewItem {
        TopViewItem(
                listType: item.listType,
                imageName: imageName(listType: item.listType),
                title: title(listType: item.listType),
                listViewItems: item.marketInfos.map { decorator.listViewItem(item: $0) }
        )
    }

    private func imageName(listType: MarketOverviewService.ListType) -> String {
        switch listType {
        case .topGainers: return "circle_up_20"
        case .topLosers: return "circle_down_20"
        }
    }

    private func title(listType: MarketOverviewService.ListType) -> String {
        switch listType {
        case .topGainers: return "market.top.section.header.top_gainers".localized
        case .topLosers: return "market.top.section.header.top_losers".localized

        }
    }

}

extension MarketOverviewViewModel {

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var marketTops: [String] {
        MarketModule.MarketTop.allCases.map { $0.title }
    }

    func marketTop(listType: MarketOverviewService.ListType) -> MarketModule.MarketTop {
        service.marketTop(listType: listType)
    }

    func marketTopIndex(listType: MarketOverviewService.ListType) -> Int {
        let marketTop = service.marketTop(listType: listType)
        return MarketModule.MarketTop.allCases.firstIndex(of: marketTop) ?? 0
    }

    func onSelect(marketTopIndex: Int, listType: MarketOverviewService.ListType) {
        let marketTop = MarketModule.MarketTop.allCases[marketTopIndex]
        service.set(marketTop: marketTop, listType: listType)
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketOverviewViewModel {

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
        let listType: MarketOverviewService.ListType
        let imageName: String
        let title: String
        let listViewItems: [MarketModule.ListViewItem]
    }

}
