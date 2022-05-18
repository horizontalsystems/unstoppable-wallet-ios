import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit
import Chart

class MarketOverviewGlobalViewModel {
    private let service: MarketOverviewGlobalService
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<DataStatus<GlobalMarketViewItem>>(value: .loading)

    init(service: MarketOverviewGlobalService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: DataStatus<MarketOverviewGlobalService.GlobalMarketData>) {
        stateRelay.accept(state.map { viewItem(globalMarketData: $0) })
    }

    private func viewItem(globalMarketData: MarketOverviewGlobalService.GlobalMarketData) -> GlobalMarketViewItem {
        GlobalMarketViewItem(
                totalMarketCap: chartViewItem(item: globalMarketData.marketCap),
                volume24h: chartViewItem(item: globalMarketData.volume24h),
                defiCap: chartViewItem(item: globalMarketData.defiMarketCap),
                defiTvl: chartViewItem(item: globalMarketData.defiTvl)
        )
    }

    private func chartViewItem(item: MarketOverviewGlobalService.GlobalMarketItem) -> ChartViewItem {
        let value = item.amount.flatMap { ValueFormatter.instance.formatShort(currency: $0.currency, value: $0.value) }

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

}

extension MarketOverviewGlobalViewModel {

    var viewItem: GlobalMarketViewItem? {
        stateRelay.value.data
    }

}

extension MarketOverviewGlobalViewModel: IMarketOverviewSectionViewModel {

    var stateObservable: Observable<DataStatus<()>> {
        stateRelay.map { $0.map { _ in () } }
    }

    func refresh() {
        service.refresh()
    }

}

extension MarketOverviewGlobalViewModel {

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

}
