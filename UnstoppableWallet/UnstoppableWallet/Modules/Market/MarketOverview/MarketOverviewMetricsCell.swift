import UIKit
import SnapKit
import ThemeKit
import HUD
import Chart
import ComponentKit

class MarketOverviewMetricsCell: UITableViewCell {
    static let cellHeight: CGFloat = 240

    weak var viewController: UIViewController?

    private let totalMarketCapView: MarketMetricView
    private let volume24hView: MarketMetricView
    private let deFiCapView: MarketMetricView
    private let deFiTvlView: MarketMetricView

    init(chartConfiguration: ChartConfiguration) {
        totalMarketCapView = MarketMetricView(configuration: chartConfiguration)
        volume24hView = MarketMetricView(configuration: chartConfiguration)
        deFiCapView = MarketMetricView(configuration: chartConfiguration)
        deFiTvlView = MarketMetricView(configuration: chartConfiguration)

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(totalMarketCapView)
        totalMarketCapView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin12)
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(MarketMetricView.height)
        }

        contentView.addSubview(volume24hView)
        volume24hView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin12)
            maker.leading.equalTo(totalMarketCapView.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.width.equalTo(totalMarketCapView.snp.width)
            maker.height.equalTo(MarketMetricView.height)
        }

        contentView.addSubview(deFiCapView)
        deFiCapView.snp.makeConstraints { maker in
            maker.top.equalTo(totalMarketCapView.snp.bottom).offset(CGFloat.margin8)
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

        totalMarketCapView.onTap = { [weak self] in self?.onTap(metricType: .totalMarketCap) }
        volume24hView.onTap = { [weak self] in self?.onTap(metricType: .volume24h) }
        deFiCapView.onTap = { [weak self] in self?.onTap(metricType: .defiCap) }
        deFiTvlView.onTap = { [weak self] in self?.onTap(metricType: .tvlInDefi) }

        totalMarketCapView.title = "market.total_market_cap".localized
        volume24hView.title = "market.24h_volume".localized
        deFiCapView.title = "market.defi_cap".localized
        deFiTvlView.title = "market.defi_tvl".localized
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func onTap(metricType: MarketGlobalModule.MetricsType) {
        let viewController = MarketGlobalMetricModule.viewController(type: metricType)
        self.viewController?.present(viewController, animated: true)
    }

}

extension MarketOverviewMetricsCell {

    func set(viewItem: MarketOverviewViewModel.GlobalMarketViewItem) {
        totalMarketCapView.set(
                value: viewItem.totalMarketCap.value,
                diff: viewItem.totalMarketCap.diff,
                chartData: viewItem.totalMarketCap.chartData,
                trend: viewItem.totalMarketCap.chartTrend
        )

        volume24hView.set(
                value: viewItem.volume24h.value,
                diff: viewItem.volume24h.diff,
                chartData: viewItem.volume24h.chartData,
                trend: viewItem.volume24h.chartTrend
        )

        deFiCapView.set(
                value: viewItem.defiCap.value,
                diff: viewItem.defiCap.diff,
                chartData: viewItem.defiCap.chartData,
                trend: viewItem.defiCap.chartTrend
        )

        deFiTvlView.set(
                value: viewItem.defiTvl.value,
                diff: viewItem.defiTvl.diff,
                chartData: viewItem.defiTvl.chartData,
                trend: viewItem.defiTvl.chartTrend
        )
    }

}
