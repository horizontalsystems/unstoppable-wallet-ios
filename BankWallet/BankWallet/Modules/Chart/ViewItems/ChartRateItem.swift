import ActionSheet

class ChartRateItem: BaseActionItem {

    let chartConfiguration: ChartConfiguration
    weak var indicatorDelegate: IChartIndicatorDelegate?

    var bind: ((ChartType, [ChartPoint], Bool) -> ())?
    var showProcess: (() -> ())?
    var showError: ((String) -> ())?

    init(tag: Int, chartConfiguration: ChartConfiguration, indicatorDelegate: IChartIndicatorDelegate?) {
        self.chartConfiguration = chartConfiguration
        self.indicatorDelegate = indicatorDelegate

        super.init(cellType: ChartRateItemView.self, tag: tag, required: true)

        showSeparator = false
        height = ChartRateTheme.chartRateHeight
    }

}
