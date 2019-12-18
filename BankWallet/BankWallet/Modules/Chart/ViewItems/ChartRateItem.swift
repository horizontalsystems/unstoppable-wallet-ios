import ActionSheet
import Chart

class ChartRateItem: BaseActionItem {

    let chartConfiguration: ChartConfiguration
    weak var indicatorDelegate: IChartIndicatorDelegate?

    var bind: ((GridIntervalType, [ChartPoint], TimeInterval?, TimeInterval?, Bool) -> ())?
    var showSpinner: (() -> ())?
    var hideSpinner: (() -> ())?
    var showError: ((String) -> ())?

    init(tag: Int, chartConfiguration: ChartConfiguration, indicatorDelegate: IChartIndicatorDelegate?) {
        self.chartConfiguration = chartConfiguration
        self.indicatorDelegate = indicatorDelegate

        super.init(cellType: ChartRateItemView.self, tag: tag, required: true)

        showSeparator = false
        height = 210
    }

}
