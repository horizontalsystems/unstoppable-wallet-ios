import UIKit
import XRatesKit
import CurrencyKit

class ChartPresenter {
    weak var view: IChartView?

    private var interactor: IChartInteractor
    private let factory: IChartRateFactory

    private var chartInfo: ChartInfo?
    private var marketInfo: MarketInfo?

    let coin: Coin
    let currency: Currency

    private var chartType: ChartType

    init(interactor: IChartInteractor, factory: IChartRateFactory, coin: Coin, currency: Currency) {
        self.interactor = interactor
        self.factory = factory
        self.coin = coin
        self.currency = currency

        chartType = interactor.defaultChartType ?? .day
    }

    private func updateChartInfo() {
        guard let chartInfo = chartInfo else {
            return
        }

        view?.hideSpinner()
        do {
            let viewItem = try factory.chartViewItem(type: chartType, chartInfo: chartInfo, currency: currency)
            view?.show(chartViewItem: viewItem)
        } catch {
            view?.showError()
        }
    }

    private func updateMarketInfo() {
        guard let marketInfo = marketInfo else {
            return
        }
        let marketInfoViewItem = factory.marketInfoViewItem(marketInfo: marketInfo, coin: coin, currency: currency)
        view?.show(marketInfoViewItem: marketInfoViewItem)
    }

    private func fetchChartInfo() {
        view?.showSpinner()

        chartInfo = interactor.chartInfo(coinCode: coin.code, currencyCode: currency.code, chartType: chartType)
        interactor.subscribeToChartInfo(coinCode: coin.code, currencyCode: currency.code, chartType: chartType)

        updateChartInfo()
    }

}

extension ChartPresenter: IChartViewDelegate {

    func viewDidLoad() {
        view?.set(types: ChartType.allCases)
        view?.set(chartType: chartType)

        marketInfo = interactor.marketInfo(coinCode: coin.code, currencyCode: currency.code)
        interactor.subscribeToMarketInfo(coinCode: coin.code, currencyCode: currency.code)
        updateMarketInfo()

        fetchChartInfo()

        view?.reloadAllModels()
    }

    func onSelect(type: ChartType) {
        guard chartType != type else {
            return
        }

        chartType = type
        interactor.defaultChartType = type

        fetchChartInfo()
    }

    func chartTouchSelect(timestamp: TimeInterval, value: Decimal, volume: Decimal?) {
        let currencyValue = CurrencyValue(currency: currency, value: value)
        let volumeValue = volume.map { CurrencyValue(currency: currency, value: $0) }
        view?.showSelectedPoint(chartType: chartType, timestamp: timestamp, value: currencyValue, volume: volumeValue)
    }

}

extension ChartPresenter: IChartInteractorDelegate {

    func didReceive(chartInfo: ChartInfo, coinCode: CoinCode) {
        guard coinCode == coin.code else {
            return
        }

        self.chartInfo = chartInfo
        updateChartInfo()
    }

    func didReceive(marketInfo: MarketInfo) {
        self.marketInfo = marketInfo
        updateMarketInfo()
    }

    func onError() {
        view?.hideSpinner()
        view?.showError()
    }

}
