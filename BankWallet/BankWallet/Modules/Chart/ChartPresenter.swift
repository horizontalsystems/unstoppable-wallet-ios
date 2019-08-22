import UIKit

class ChartPresenter {
    weak var view: IChartView?

    private let interactor: IChartInteractor
    private let chartRateConverter: IChartRateConverter
    private let coin: Coin
    private let currency: Currency

    private var chartType: ChartType

    private var animated: Bool = true

    init(interactor: IChartInteractor, chartRateConverter: IChartRateConverter, coin: Coin, currency: Currency) {
        self.interactor = interactor
        self.chartRateConverter = chartRateConverter
        self.coin = coin
        self.currency = currency

        chartType = interactor.defaultChartType
    }

}

extension ChartPresenter: IChartViewDelegate {

    func viewDidLoad() {
        view?.bindTitle(coin: coin)

        if let rate = interactor.currentRate(coinCode: coin.code, currencyCode: currency.code) {
            view?.bind(currentRateValue: CurrencyValue(currency: currency, value: rate.value))
        }

        view?.addTypeButtons(types: ChartType.allCases)
        view?.setButtonSelected(tag: interactor.defaultChartType.tag)

        interactor.getMarketCap()

        view?.showProgress()
        interactor.getRates(coinCode: coin.code, currencyCode: currency.code, chartType: chartType)

        view?.reloadAllModels()
    }

    func didSelect(type: ChartType) {
        guard chartType != type else {
            return
        }

        chartType = type
        interactor.set(chartType: type)

        view?.showProgress()
        interactor.getRates(coinCode: coin.code, currencyCode: currency.code, chartType: chartType)
    }

    func chartTap(point: ChartPoint) {
        let currencyValue = CurrencyValue(currency: currency, value: point.value)
        view?.showSelectedData(timestamp: point.timestamp, value: currencyValue)
    }

}

extension ChartPresenter: IChartInteractorDelegate {

    func didReceive(chartData: ChartRateData) {
        let points = chartRateConverter.convert(chartRateData: chartData)

        var minimumValue: Decimal = Decimal.greatestFiniteMagnitude
        var maximumValue: Decimal = Decimal.zero
        points.forEach { point in
            minimumValue = min(minimumValue, point.value)
            maximumValue = max(maximumValue, point.value)
        }

        if let first = points.first?.value,
           let last = points.last?.value {
            view?.bind(diff: last - first)
        } else {
            view?.bind(diff: nil)
        }

        view?.bind(type: chartType, lowValue: CurrencyValue(currency: currency, value: minimumValue))
        view?.bind(type: chartType, highValue: CurrencyValue(currency: currency, value: maximumValue))
        view?.bind(type: chartType, chartPoints: points, animated: animated)

        animated = false
    }

    func didReceive(marketCapData: MarketCapData) {
        guard let rate = interactor.currentRate(coinCode: coin.code, currencyCode: currency.code),
              let coin = marketCapData.coins[coin.code] else {
            view?.bind(marketCapValue: nil, postfix: nil)
            return
        }
        do {
            let marketCapData = try MarketCapFormatter.marketCap(circulatingSupply: Decimal(coin.supply), rate: rate.value)
            view?.bind(marketCapValue: CurrencyValue(currency: currency, value: marketCapData.value), postfix: marketCapData.postfix)
        } catch {
            view?.bind(marketCapValue: nil, postfix: nil)
        }
    }

    func onChartError(_ error: Error) {
        view?.show(error: "Something wrong!")
    }

    func onMarketCapError(_ error: Error) {
        view?.bind(marketCapValue: nil, postfix: nil)
    }

}
