import Foundation
import XRatesKit
import CurrencyKit
import Chart

protocol IChartView: class {
    func set(title: String)
    func set(viewItem: ChartViewItem)
    func set(types: [String])

    func showSelectedPoint(viewItem: SelectedPointViewItem)
    func hideSelectedPoint()
}

protocol IChartViewDelegate {
    var currency: Currency { get }

    func onLoad()

    func onSelectChartType(at index: Int)
    func onTapPost(at index: Int)
}

protocol IChartInteractor {
    var defaultChartType: ChartType? { get set }

    func chartInfo(coinCode: CoinCode, currencyCode: String, chartType: ChartType) -> ChartInfo?
    func subscribeToChartInfo(coinCode: CoinCode, currencyCode: String, chartType: ChartType)

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo?
    func subscribeToMarketInfo(coinCode: CoinCode, currencyCode: String)

    func posts(coinCode: CoinCode) -> [CryptoNewsPost]?
    func subscribeToPosts(coinCode: CoinCode)
}

protocol IChartInteractorDelegate: class {
    func didReceive(chartInfo: ChartInfo, coinCode: CoinCode)
    func didReceive(marketInfo: MarketInfo)
    func didReceive(posts: [CryptoNewsPost])
    func onChartInfoError()
    func onPostsError()
}

protocol IChartRouter {
    func open(link: String)
}

protocol IChartRateFactory {
    func chartViewItem(type: ChartType, allTypes: [ChartType], chartInfoStatus: ChartDataStatus<ChartInfo>, marketInfoStatus: ChartDataStatus<MarketInfo>,
                       postsStatus: ChartDataStatus<[CryptoNewsPost]>, coinCode: String, currency: Currency) -> ChartViewItem
    func selectedPointViewItem(type: ChartType, chartPoint: Chart.ChartPoint, currency: Currency) -> SelectedPointViewItem
}


struct PostViewItem {
    let title: String
    let subtitle: String
}

struct ChartInfoViewItem {
    let gridIntervalType: GridIntervalType

    let points: [Chart.ChartPoint]
    let startTimestamp: TimeInterval
    let endTimestamp: TimeInterval
}

struct MarketInfoViewItem {
    let marketCap: String?
    let volume: String?
    let supply: String?
    let maxSupply: String?
}

struct SelectedPointViewItem {
    let date: String
    let time: String?
    let value: String?
    let volume: String?
}

struct ChartViewItem {
    let selectedIndex: Int

    let diff: Decimal?
    let currentRate: String?

    let chartInfoStatus: ChartDataStatus<ChartInfoViewItem>
    let marketInfoStatus: ChartDataStatus<MarketInfoViewItem>
    let postsStatus: ChartDataStatus<[PostViewItem]>
}
