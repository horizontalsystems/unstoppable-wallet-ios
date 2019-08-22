import UIKit
import ActionSheet

class ChartViewController: ActionSheetController {
    private let delegate: IChartViewDelegate

    private static let diffFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    private let titleItem = ActionTitleItem(tag: 0)
    private let currentRateItem = ChartCurrentRateItem(tag: 1)
    private let chartRateTypeItem = ChartRateTypeItem(tag: 2)
    private var chartRateItem: ChartRateItem?
    private var marketCapItem = ChartMarketCapItem(tag: 4)

    init(delegate: IChartViewDelegate) {
        self.delegate = delegate
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

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

}

extension ChartViewController: IChartView {

    public func bindTitle(coin: Coin) {
        titleItem.bindTitle?("%@ Rate".localized(coin.title), coin)
    }

    func bind(currentRateValue: CurrencyValue) {
        let formattedValue = ValueFormatter.instance.format(currencyValue: currentRateValue)
        currentRateItem.bindRate?(formattedValue)
    }

    func bind(diff: Decimal?) {
        guard let diff = diff else {
            currentRateItem.bindDiff?(nil, true)
            return
        }
        let formattedDiff = ChartViewController.diffFormatter.string(from: diff as NSNumber)
        currentRateItem.bindDiff?(formattedDiff, !diff.isSignMinus)
    }

    func addTypeButtons(types: [ChartType]) {
        for type in types {
            chartRateTypeItem.bindButton?(type.title, type.tag) { [weak self] in
                self?.delegate.didSelect(type: type)
            }
        }
    }

    func setButtonSelected(tag: Int) {
        chartRateTypeItem.setSelected?(tag)
    }

    func bind(type: ChartType, chartPoints: [ChartPoint], animated: Bool) {
        chartRateItem?.bind?(type, chartPoints, animated)
    }

    func bind(marketCapValue: CurrencyValue?, postfix: String?) {
        marketCapItem.setMarketCapTitle?("M. CAP")

        guard let value = marketCapValue, let formattedValue = ValueFormatter.instance.format(currencyValue: value) else {
            marketCapItem.setMarketCapText?(nil)
            return
        }
        let formattedMarketCapString = [formattedValue, postfix].compactMap { $0 }.joined(separator: " ")
        marketCapItem.setMarketCapText?(formattedMarketCapString)
    }

    func bind(type: ChartType, lowValue: CurrencyValue?) {
        marketCapItem.setLowTitle?("\(type.title) Low")

        guard let lowValue = lowValue else {
            marketCapItem.setLowText?(nil)
            return
        }
        let formattedValue = ValueFormatter.instance.format(currencyValue: lowValue)
        marketCapItem.setLowText?(formattedValue)
    }

    func bind(type: ChartType, highValue: CurrencyValue?) {
        marketCapItem.setHighTitle?("\(type.title) High")

        guard let highValue = highValue else {
            marketCapItem.setHighText?(nil)
            return
        }
        let formattedValue = ValueFormatter.instance.format(currencyValue: highValue)
        marketCapItem.setHighText?(formattedValue)
    }

    func showSelectedData(timestamp: TimeInterval, value: CurrencyValue) {
        let date = Date(timeIntervalSince1970: timestamp)
        let formattedDate = DateHelper.instance.formatTransactionInfoTime(from: date)
        let formattedValue = ValueFormatter.instance.format(currencyValue: value)

        chartRateTypeItem.showPoint?(formattedDate, formattedValue)
    }

    func reloadAllModels() {
        model.reload?()
    }

    func showProgress() {
        chartRateItem?.showProcess?()
    }

    func show(error: String) {
        chartRateItem?.showError?(error)
    }

}

extension ChartViewController: IChartIndicatorDelegate {

    func didTap(chartPoint: ChartPoint) {
        delegate.chartTap(point: chartPoint)
    }

    func didFinishTap() {
        chartRateTypeItem.showPoint?(nil, nil)
    }

}
