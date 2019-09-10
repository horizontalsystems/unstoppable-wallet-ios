import UIKit
import ActionSheet

class ChartViewController: ActionSheetController {
    private let delegate: IChartViewDelegate

    private static let marketCapFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

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

    private func showSubtitle(for date: Date?) {
        guard let date = date else {
            titleItem.bindSubtitle?(nil)
            return
        }
        titleItem.bindSubtitle?(DateHelper.instance.formatFullTime(from: date))
    }

    private func show(currentRateValue: CurrencyValue?) {
        guard let currentRateValue = currentRateValue else {
            currentRateItem.bindRate?(nil)
            return
        }
        let formattedValue = ValueFormatter.instance.format(currencyValue: currentRateValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        currentRateItem.bindRate?(formattedValue)
    }

    private func show(diff: Decimal) {
        currentRateItem.bindDiff?(ChartRateTheme.formatted(percentDelta: diff), !diff.isSignMinus)
    }

    private func marketCapFormat(currencyValue: CurrencyValue) -> String? {
        let formatter = ChartViewController.marketCapFormatter
        formatter.currencyCode = currencyValue.currency.code
        formatter.currencySymbol = currencyValue.currency.symbol
        formatter.maximumFractionDigits = 1

        return formatter.string(from: currencyValue.value as NSNumber)
    }

    private func show(marketCapValue: CurrencyValue?) {
        guard let marketCapValue = marketCapValue else {
            marketCapItem.setMarketCapText?(nil)
            marketCapItem.setMarketCapTitle?(nil)
            return
        }
        let marketCapData = MarketCapFormatter.marketCap(value: marketCapValue.value)
        guard let formattedValue = marketCapFormat(currencyValue: CurrencyValue(currency: marketCapValue.currency, value: marketCapData.value)) else {
            marketCapItem.setMarketCapText?(nil)
            marketCapItem.setMarketCapTitle?(nil)
            return
        }

        let marketCapText = marketCapData.postfix?.localized(formattedValue) ?? formattedValue
        marketCapItem.setMarketCapText?(marketCapText)
        marketCapItem.setMarketCapTitle?("chart.market_cap".localized)
    }

    private func show(lowValue: CurrencyValue?) {
        marketCapItem.setLowTitle?("chart.low".localized)

        guard let lowValue = lowValue else {
            marketCapItem.setLowText?(nil)
            return
        }
        let formattedValue = ValueFormatter.instance.format(currencyValue: lowValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        marketCapItem.setLowText?(formattedValue)
    }

    private func show(highValue: CurrencyValue?) {
        marketCapItem.setHighTitle?("chart.high".localized)

        guard let highValue = highValue else {
            marketCapItem.setHighText?(nil)
            return
        }
        let formattedValue = ValueFormatter.instance.format(currencyValue: highValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        marketCapItem.setHighText?(formattedValue)
    }

}

extension ChartViewController: IChartView {

    func show(viewItem: ChartViewItem) {
        showSubtitle(for: viewItem.latestRateDate)
        show(currentRateValue: viewItem.rateValue)
        show(diff: viewItem.diff)

        chartRateItem?.bind?(viewItem.type, viewItem.points, true)

        show(marketCapValue: viewItem.marketCapValue)
        show(highValue: viewItem.highValue)
        show(lowValue: viewItem.lowValue)
    }

    func addTypeButtons(types: [ChartType]) {
        for type in types {
            chartRateTypeItem.bindButton?(type.title, type.tag) { [weak self] in
                self?.delegate.onSelect(type: type)
            }
        }
    }

    func setChartTypeEnabled(tag: Int) {
        chartRateTypeItem.setEnabled?(tag)
    }

    func setChartType(tag: Int) {
        chartRateTypeItem.setSelected?(tag)
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

    func didTap(chartPoint: ChartPoint) {
        delegate.chartTouchSelect(point: chartPoint)
    }

    func didFinishTap() {
        chartRateTypeItem.showPoint?(nil, nil)
    }

}
