import UIKit
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa
import HUD
import Chart
import ComponentKit

class MarketMetricsCellNew: UITableViewCell {
    static let cellHeight: CGFloat = 268

    private let viewModel: MarketMetricsViewModel
    private let disposeBag = DisposeBag()

    private let marketLargeView = MarketMetricLargeView()
    private let volume24hView: MarketMetricView
    private let btcDominanceView: MarketMetricView
    private let deFiCapView: MarketMetricView
    private let deFiTvlView: MarketMetricView

    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = ErrorView()

    private var tapMetricRelay = PublishRelay<MarketGlobalModule.MetricsType>()

    init(viewModel: MarketMetricsViewModel, chartConfiguration: ChartConfiguration) {
        self.viewModel = viewModel

        volume24hView = MarketMetricView(configuration: chartConfiguration)
        btcDominanceView = MarketMetricView(configuration: chartConfiguration)
        deFiCapView = MarketMetricView(configuration: chartConfiguration)
        deFiTvlView = MarketMetricView(configuration: chartConfiguration)

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(marketLargeView)
        marketLargeView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin12)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightCell48)
        }

        contentView.addSubview(btcDominanceView)
        btcDominanceView.snp.makeConstraints { maker in
            maker.top.equalTo(marketLargeView.snp.bottom).offset(CGFloat.margin16)
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(MarketMetricView.height)
        }

        contentView.addSubview(volume24hView)
        volume24hView.snp.makeConstraints { maker in
            maker.top.equalTo(marketLargeView.snp.bottom).offset(CGFloat.margin16)
            maker.leading.equalTo(btcDominanceView.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.width.equalTo(btcDominanceView.snp.width)
            maker.height.equalTo(MarketMetricView.height)
        }

        contentView.addSubview(deFiCapView)
        deFiCapView.snp.makeConstraints { maker in
            maker.top.equalTo(btcDominanceView.snp.bottom).offset(CGFloat.margin8)
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(MarketMetricView.height)
        }

        contentView.addSubview(deFiTvlView)
        deFiTvlView.snp.makeConstraints { maker in
            maker.top.equalTo(volume24hView.snp.bottom).offset(CGFloat.margin8)
            maker.leading.equalTo(deFiCapView.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.width.equalTo(deFiCapView.snp.width)
            maker.height.equalTo(MarketMetricView.height)
        }

        btcDominanceView.onTap = { [weak self] in self?.onTap(metricType: .btcDominance) }
        volume24hView.onTap = { [weak self] in self?.onTap(metricType: .volume24h) }
        deFiCapView.onTap = { [weak self] in self?.onTap(metricType: .defiCap) }
        deFiTvlView.onTap = { [weak self] in self?.onTap(metricType: .tvlInDefi) }

        contentView.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.bottom.equalTo(btcDominanceView.snp.top).offset(-CGFloat.margin16)
        }

        contentView.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.bottom.equalTo(btcDominanceView.snp.top).offset(-CGFloat.margin16)
        }

        marketLargeView.title = "market.total_market_cap".localized
        volume24hView.title = "market.24h_volume".localized
        btcDominanceView.title = "market.btc_dominance".localized
        deFiCapView.title = "market.defi_cap".localized
        deFiTvlView.title = "market.defi_tvl".localized

        subscribe(disposeBag, viewModel.metricsDriver) { [weak self] in self?.sync(marketMetrics: $0) }
        subscribe(disposeBag, viewModel.isLoadingDriver) { [weak self] in self?.sync(isLoading: $0) }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] in self?.sync(error: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func onTap(metricType: MarketGlobalModule.MetricsType) {
        tapMetricRelay.accept(metricType)
    }

    private func sync(marketMetrics: MarketMetricsViewModel.MarketMetrics?) {
        guard let marketMetrics = marketMetrics else {
            marketLargeView.clear()
            volume24hView.clear()
            btcDominanceView.clear()
            deFiCapView.clear()
            deFiTvlView.clear()

            return
        }

        marketLargeView.set(value: marketMetrics.totalMarketCap.value,
                diff: marketMetrics.totalMarketCap.diff
        )

        volume24hView.set(
                value: marketMetrics.volume24h.value,
                diff: marketMetrics.volume24h.diff,
                chartData: marketMetrics.volume24h.chartData,
                trend: marketMetrics.volume24h.chartTrend
        )

        btcDominanceView.set(
                value: marketMetrics.btcDominance.value,
                diff: marketMetrics.btcDominance.diff,
                chartData: marketMetrics.btcDominance.chartData,
                trend: marketMetrics.btcDominance.chartTrend
        )

        deFiCapView.set(
                value: marketMetrics.defiCap.value,
                diff: marketMetrics.defiCap.diff,
                chartData: marketMetrics.defiCap.chartData,
                trend: marketMetrics.defiCap.chartTrend
        )

        deFiTvlView.set(
                value: marketMetrics.defiTvl.value,
                diff: marketMetrics.defiTvl.diff,
                chartData: marketMetrics.defiTvl.chartData,
                trend: marketMetrics.defiTvl.chartTrend
        )
    }

    private func sync(isLoading: Bool) {
        if isLoading {
            spinner.isHidden = false
            spinner.startAnimating()
        } else {
            spinner.isHidden = true
            spinner.stopAnimating()
        }
    }

    private func sync(error: String?) {
        errorView.isHidden = error == nil
        errorView.text = error
    }

}

extension MarketMetricsCellNew {

    var onTapMetricsSignal: Signal<MarketGlobalModule.MetricsType> {
        tapMetricRelay.asSignal()
    }

    func refresh() {
        viewModel.refresh()
    }

}
