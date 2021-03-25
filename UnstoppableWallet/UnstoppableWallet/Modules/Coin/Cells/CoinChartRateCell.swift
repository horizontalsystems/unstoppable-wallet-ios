import RxSwift

class CoinChartRateCell: ChartCurrentRateCell {
    private let disposeBag = DisposeBag()
    private let viewModel: CoinChartViewModel

    init(viewModel: CoinChartViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        subscribe(disposeBag, viewModel.rateDriver) { [weak self] in self?.sync(rate: $0) }
        subscribe(disposeBag, viewModel.chartInfoDriver) { [weak self] in self?.sync(chartInfo: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sync(rate: String?) {
        self.rate = rate
    }

    private func sync(chartInfo: CoinChartViewModel.ViewItem?) {
        set(diff: chartInfo?.chartDiff)
    }

}
