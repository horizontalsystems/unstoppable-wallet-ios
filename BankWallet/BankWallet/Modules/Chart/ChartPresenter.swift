import UIKit
import XRatesKit
import CurrencyKit
import Chart

class ChartPresenter {
    private let types = ChartType.allCases

    weak var view: IChartView?

    private var interactor: IChartInteractor
    private let router: IChartRouter
    private let factory: IChartRateFactory

    private var marketInfo: MarketInfo?
    private var marketInfoStatus: ChartDataStatus<MarketInfo> = .loading
    private var chartInfoStatus: ChartDataStatus<ChartInfo> = .loading
    private var postsStatus: ChartDataStatus<[CryptoNewsPost]> = .loading

    let coin: Coin
    let currency: Currency

    private var chartType: ChartType

    init(interactor: IChartInteractor, router: IChartRouter, factory: IChartRateFactory, coin: Coin, currency: Currency) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.coin = coin
        self.currency = currency

        chartType = interactor.defaultChartType ?? .day
    }

    private func updateView() {

        let viewItem = factory.chartViewItem(type: chartType,
                allTypes: types,
                chartInfoStatus: chartInfoStatus,
                marketInfoStatus: marketInfoStatus,
                postsStatus: postsStatus,
                coin: coin,
                currency: currency)

        view?.set(viewItem: viewItem)
    }

    private func fetchInfo() {
        chartInfoStatus = ChartDataStatus(data: interactor.chartInfo(coinCode: coin.code, currencyCode: currency.code, chartType: chartType))
        interactor.subscribeToChartInfo(coinCode: coin.code, currencyCode: currency.code, chartType: chartType)

        marketInfoStatus = ChartDataStatus(data: interactor.marketInfo(coinCode: coin.code, currencyCode: currency.code))
        interactor.subscribeToMarketInfo(coinCode: coin.code, currencyCode: currency.code)

        if let posts = interactor.posts(coinCode: coin.code) {
            postsStatus = .completed(posts)
        } else {
            self.postsStatus = .loading
            interactor.subscribeToPosts(coinCode: coin.code)
        }

        updateView()
    }

}

extension ChartPresenter: IChartViewDelegate {

    func onLoad() {
        view?.set(title: coin.title)
        view?.set(types: types.map { $0.title })

        fetchInfo()
    }

    func onSelectChartType(at index: Int) {
        guard types.count > index else {
            return
        }
        chartType = types[index]
        interactor.defaultChartType = chartType

        fetchInfo()
    }

    func onTapPost(at index: Int) {
        guard let posts = postsStatus.data else {
            return
        }
        router.open(link: posts[index].url)
    }

}

extension ChartPresenter: IChartInteractorDelegate {

    func didReceive(chartInfo: ChartInfo, coinCode: CoinCode) {
        guard coinCode == coin.code else {
            return
        }
        chartInfoStatus = .completed(chartInfo)
        updateView()
    }

    func didReceive(marketInfo: MarketInfo) {
        marketInfoStatus = .completed(marketInfo)
        updateView()
    }

    func didReceive(posts: [CryptoNewsPost]) {
        self.postsStatus = .completed(posts)
        updateView()
    }

    func onChartInfoError() {
        chartInfoStatus = .failed
        updateView()
    }

    func onPostsError() {
        self.postsStatus = .failed
        updateView()
    }

}

extension ChartPresenter: IChartIndicatorDelegate {

    public func didTap(chartPoint: Chart.ChartPoint) {
        view?.showSelectedPoint(viewItem: factory.selectedPointViewItem(type: chartType, chartPoint: chartPoint, coin: coin, currency: currency))
    }

    public func didFinishTap() {
        view?.hideSelectedPoint()
    }

}
