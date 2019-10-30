import UIKit
import ActionSheet
import XRatesKit

class ChartViewController: ActionSheetController {
    private let delegate: IChartViewDelegate

    private let titleItem: AlertTitleItem
    private let currentRateItem = ChartCurrentRateItem(tag: 1)
    private let chartRateTypeItem = ChartRateTypeItem(tag: 2)
    private var chartRateItem: ChartRateItem?
    private var marketCapItem = ChartMarketCapItem(tag: 4)

    init(delegate: IChartViewDelegate) {
        self.delegate = delegate

        let coin = delegate.coin
        titleItem = AlertTitleItem(
                title: "chart.title".localized(coin.title),
                icon: UIImage(coin: coin),
                iconTintColor: AppTheme.coinIconColor,
                tag: 0
        )

        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

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

        let chartRateItem = ChartRateItem(tag: 3, chartConfiguration: ChartConfiguration(), indicatorDelegate: self)
        self.chartRateItem = chartRateItem

        model.addItemView(chartRateItem)
        model.addItemView(marketCapItem)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = .crypto_Dark_Bars
        model.hideInBackground = false

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

    private func show(lowValue: CurrencyValue?) {
        guard let lowValue = lowValue else {
            marketCapItem.setLow?(nil)
            return
        }

        let formattedValue = ValueFormatter.instance.format(currencyValue: lowValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        marketCapItem.setLow?(formattedValue)
    }

    private func show(highValue: CurrencyValue?) {
        guard let highValue = highValue else {
            marketCapItem.setHigh?(nil)
            return
        }
        let formattedValue = ValueFormatter.instance.format(currencyValue: highValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        marketCapItem.setHigh?(formattedValue)
    }

    private func show(marketCapValue: CurrencyValue?) {
        marketCapItem.setMarketCap?(CurrencyCompactFormatter.instance.format(currencyValue: marketCapValue))
    }

    private func show(volumeValue: CurrencyValue?) {
        marketCapItem.setVolume?(CurrencyCompactFormatter.instance.format(currencyValue: volumeValue))
    }

    private func show(supplyValue: CoinValue?) {
        guard let supplyValue = supplyValue else {
            marketCapItem.setCirculation?(nil)
            return
        }
        marketCapItem.setCirculation?(ValueFormatter.instance.format(coinValue: supplyValue))
    }

    private func title(for chartType: ChartType) -> String {
        switch chartType {
        case .day: return "chart.time_duration.day".localized
        case .week: return "chart.time_duration.week".localized
        case .month: return "chart.time_duration.month".localized
        case .halfYear: return "chart.time_duration.halyear".localized
        case .year: return "chart.time_duration.year".localized
        }
    }

}

extension ChartViewController: IChartView {

    func show(chartViewItem viewItem: ChartInfoViewItem) {
        show(diff: viewItem.diff)
        chartRateItem?.bind?(viewItem.gridIntervalType, viewItem.points, viewItem.startTimestamp, viewItem.endTimestamp, true)

        show(highValue: viewItem.highValue)
        show(lowValue: viewItem.lowValue)
    }

    func show(marketInfoViewItem viewItem: MarketInfoViewItem) {
        showSubtitle(for: viewItem.timestamp)
        show(currentRateValue: viewItem.rateValue)

        show(marketCapValue: viewItem.marketCapValue)
        show(volumeValue: viewItem.volumeValue)
        show(supplyValue: viewItem.supplyValue)
    }

    func addTypeButtons(types: [ChartType]) {
        for type in types {
            let typeTitle = title(for: type)
            chartRateTypeItem.bindButton?(typeTitle, type.rawValue) { [weak self] in
                self?.delegate.onSelect(type: type)
                self?.marketCapItem.setTypeTitle?(typeTitle)
            }
        }
    }

    func setChartTypeEnabled(tag: Int) {
        chartRateTypeItem.setEnabled?(tag)
    }

    func set(chartType: ChartType) {
        chartRateTypeItem.setSelected?(chartType.rawValue)
        marketCapItem.setTypeTitle?(title(for: chartType))
    }

    func showSelectedPoint(chartType: ChartType, timestamp: TimeInterval, value: CurrencyValue) {
        let date = Date(timeIntervalSince1970: timestamp)
        let formattedDate = [ChartType.month, ChartType.halfYear, ChartType.year].contains(chartType) ? DateHelper.instance.formatFullDateOnly(from: date) : DateHelper.instance.formatFullTime(from: date)
        let formattedValue = ValueFormatter.instance.format(currencyValue: value, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)

        chartRateTypeItem.showPoint?(formattedDate, formattedValue)
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

    func didTap(chartPoint: ChartPointPosition) {
        delegate.chartTouchSelect(timestamp: chartPoint.timestamp, value: chartPoint.value)
    }

    func didFinishTap() {
        chartRateTypeItem.showPoint?(nil, nil)
    }

}
