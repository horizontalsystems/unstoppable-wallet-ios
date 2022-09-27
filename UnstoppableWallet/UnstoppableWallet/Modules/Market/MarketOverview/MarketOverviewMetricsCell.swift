import UIKit
import SnapKit
import ThemeKit
import HUD
import Chart
import ComponentKit

class MarketOverviewMetricsCell: UITableViewCell {
    static let cellHeight: CGFloat = 250

    private weak var presentDelegate: IPresentDelegate?

    private let totalMarketCapView: MarketCardView
    private let volume24hView: MarketCardView
    private let deFiCapView: MarketCardView
    private let deFiTvlView: MarketCardView

    init(chartConfiguration: ChartConfiguration, presentDelegate: IPresentDelegate) {
        self.presentDelegate = presentDelegate

        totalMarketCapView = MarketCardView()
        volume24hView = MarketCardView()
        deFiCapView = MarketCardView()
        deFiTvlView = MarketCardView()

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(totalMarketCapView)
        totalMarketCapView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin12)
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(MarketCardView.height)
        }

        contentView.addSubview(volume24hView)
        volume24hView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin12)
            maker.leading.equalTo(totalMarketCapView.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.width.equalTo(totalMarketCapView.snp.width)
            maker.height.equalTo(MarketCardView.height)
        }

        contentView.addSubview(deFiCapView)
        deFiCapView.snp.makeConstraints { maker in
            maker.top.equalTo(totalMarketCapView.snp.bottom).offset(CGFloat.margin8)
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(MarketCardView.height)
        }

        contentView.addSubview(deFiTvlView)
        deFiTvlView.snp.makeConstraints { maker in
            maker.top.equalTo(volume24hView.snp.bottom).offset(CGFloat.margin8)
            maker.leading.equalTo(deFiCapView.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.width.equalTo(deFiCapView.snp.width)
            maker.height.equalTo(MarketCardView.height)
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
        presentDelegate?.present(viewController: viewController)
    }

}

extension MarketOverviewMetricsCell {

    func set(viewItem: MarketOverviewGlobalViewModel.GlobalMarketViewItem) {
        totalMarketCapView.set(viewItem: viewItem.totalMarketCap)
        volume24hView.set(viewItem: viewItem.volume24h)
        deFiCapView.set(viewItem: viewItem.defiCap)
        deFiTvlView.set(viewItem: viewItem.defiTvl)
    }

}

extension MarketCardView {

    func set(viewItem: MarketOverviewGlobalViewModel.ChartViewItem) {
        value = viewItem.value
        descriptionText = DiffLabel.formatted(value: viewItem.diff)
        descriptionColor = DiffLabel.color(value: viewItem.diff)
        set(chartData: viewItem.chartData, trend: viewItem.chartTrend)
    }

}
