import UIKit
import ActionSheet
import XRatesKit
import Chart
import CurrencyKit

extension ChartType {

    var title: String {
        switch self {
            case .day: return "chart.time_duration.day".localized
            case .week: return "chart.time_duration.week".localized
            case .month: return "chart.time_duration.month".localized
            case .month3: return "chart.time_duration.month3".localized
            case .halfYear: return "chart.time_duration.halyear".localized
            case .year: return "chart.time_duration.year".localized
            case .year2: return "chart.time_duration.year2".localized
        }
    }

}

class ChartViewController: WalletActionSheetController {
    private let coinFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 8
        return formatter
    }()

    private let delegate: IChartViewDelegate

    private let titleItem: AlertTitleItem
    private let currentRateItem = ChartCurrentRateItem(tag: 1)
    private let chartRateTypeItem = ChartRateTypeItem(tag: 2)
    private var chartRateItem: ChartRateItem?
    private var marketCapItem = ChartMarketCapItem(tag: 4)

    private var types = [ChartType]()

    init(delegate: IChartViewDelegate) {
        self.delegate = delegate

        let coin = delegate.coin
        titleItem = AlertTitleItem(
                title: "chart.title".localized(coin.title),
                icon: UIImage(coin: coin),
                iconTintColor: .themeGray,
                tag: 0
        )

        super.init()

        titleItem.onClose = { [weak self] in
            self?.dismiss(byFade: false)
        }

        initItems()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initItems() {
        model.addItemView(titleItem)
        model.addItemView(currentRateItem)
        model.addItemView(chartRateTypeItem)

        let chartRateItem = ChartRateItem(tag: 3, chartConfiguration: ChartConfiguration.fullChart(currency: delegate.currency), indicatorDelegate: self)
        self.chartRateItem = chartRateItem

        model.addItemView(chartRateItem)
        model.addItemView(marketCapItem)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        model.hideInBackground = false

        chartRateTypeItem.didSelect = { [weak self] index in
            self?.didSelect(index: index)
        }
        delegate.viewDidLoad()
    }

    private func showSubtitle(for timestamp: TimeInterval?) {
        guard let timestamp = timestamp else {
            titleItem.bindSubtitle?(nil)
            return
        }
        titleItem.bindSubtitle?(DateHelper.instance.formatFullTime(from: Date(timeIntervalSince1970: timestamp)))
    }

    private func show(currentRateValue: CurrencyValue?) {
        guard let currentRateValue = currentRateValue else {
            currentRateItem.bindRate?(nil)
            return
        }
        let formattedValue = ValueFormatter.instance.format(currencyValue: currentRateValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        currentRateItem.bindRate?(formattedValue)
    }

    private func show(diff: Decimal?) {
        currentRateItem.bindDiff?(diff)
    }

    private func show(marketCapValue: CurrencyValue?) {
        marketCapItem.setMarketCap?(CurrencyCompactFormatter.instance.format(currencyValue: marketCapValue))
    }

    private func show(volumeValue: CurrencyValue?) {
        marketCapItem.setVolume?(CurrencyCompactFormatter.instance.format(currencyValue: volumeValue))
    }

    private func show(supplyValue: CoinValue?) {
        marketCapItem.setCirculation?(roundedFormat(coinValue: supplyValue))
    }

    private func show(maxSupply: CoinValue?) {
        marketCapItem.setTotal?(roundedFormat(coinValue: maxSupply) ?? "n/a".localized)
    }

    private func roundedFormat(coinValue: CoinValue?) -> String? {
        guard let coinValue = coinValue, let formattedValue = coinFormatter.string(from: coinValue.value as NSNumber) else {
            return nil
        }

        return "\(formattedValue) \(coinValue.coin.code)"
    }

    private func didSelect(index: Int) {
        guard types.count > index else {
            return
        }
        delegate.onSelect(type: types[index])
    }

}

extension ChartViewController: IChartView {

    func show(chartViewItem viewItem: ChartInfoViewItem) {
        show(diff: viewItem.diff)
        chartRateItem?.bind?(viewItem.gridIntervalType, viewItem.points, viewItem.startTimestamp, viewItem.endTimestamp, true)
    }

    func show(marketInfoViewItem viewItem: MarketInfoViewItem) {
        showSubtitle(for: viewItem.timestamp)
        show(currentRateValue: viewItem.rateValue)

        show(marketCapValue: viewItem.marketCapValue)
        show(volumeValue: viewItem.volumeValue)
        show(supplyValue: viewItem.supplyValue)
        show(maxSupply: viewItem.maxSupplyValue)
    }

    func set(types: [ChartType]) {
        self.types = types
        chartRateTypeItem.setTitles?(types.map { $0.title })
    }

    func set(chartType: ChartType) {
        if let index = types.firstIndex(of: chartType) {
            chartRateTypeItem.setSelected?(index)
        }
    }

    func showSelectedPoint(chartType: ChartType, timestamp: TimeInterval, value: CurrencyValue, volume: CurrencyValue?) {
        let date = Date(timeIntervalSince1970: timestamp)
        let formattedTime = [ChartType.day, ChartType.week].contains(chartType) ? DateHelper.instance.formatTimeOnly(from: date) : nil
        let formattedDate = DateHelper.instance.formateShortDateOnly(date: date)

        currencyFormatter.currencyCode = value.currency.code
        currencyFormatter.currencySymbol = value.currency.symbol
        let formattedValue = currencyFormatter.string(from: value.value as NSNumber)

        chartRateTypeItem.showPoint?(formattedDate, formattedTime, formattedValue, CurrencyCompactFormatter.instance.format(currencyValue: volume))
    }

    func reloadAllModels() {
        model.reload?()
    }

    func showSpinner() {
        chartRateItem?.showSpinner?()
    }

    func hideSpinner() {
        chartRateItem?.hideSpinner?()
    }

    func showError() {
        chartRateItem?.showError?("chart.error.not_available".localized)
    }

}

extension ChartViewController: IChartIndicatorDelegate {

    func didTap(chartPoint: Chart.ChartPoint) {
        delegate.chartTouchSelect(timestamp: chartPoint.timestamp, value: chartPoint.value, volume: chartPoint.volume)
    }

    func didFinishTap() {
        chartRateTypeItem.showPoint?(nil, nil, nil, nil)
    }

}
