import RxSwift

class MarketGlobalCurrentInfoCell: ChartCurrentRateCell {
    private let disposeBag = DisposeBag()
    private let viewModel: MarketGlobalChartViewModel

    init(viewModel: MarketGlobalChartViewModel) {
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

    private func sync(chartInfo: MarketGlobalChartViewModel.ViewItem?) {
        rate = chartInfo?.currentValue
        set(diff: chartInfo?.chartDiff)
    }

}
