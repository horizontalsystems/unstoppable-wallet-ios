import RxSwift

class MetricChartCurrentInfoCell: ChartCurrentRateCell {
    private let disposeBag = DisposeBag()
    private let viewModel: MetricChartViewModel

    init(viewModel: MetricChartViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        subscribe(disposeBag, viewModel.chartInfoDriver) { [weak self] in self?.sync(chartInfo: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sync(rate: String?) {
        self.rate = rate
    }

    private func sync(chartInfo: MetricChartViewModel.ViewItem?) {
        rate = chartInfo?.currentValue
        set(diff: chartInfo?.chartDiff)
    }

}
