import Chart
import ComponentKit
import HUD
import SnapKit
import ThemeKit
import UIKit

class MarketOverviewMetricsCell: UITableViewCell {
    static let cellHeight: CGFloat = MarketCardView.height + 2 * .margin16

    private weak var presentDelegate: IPresentDelegate?

    private let totalMarketCapView: MarketCardView
    private let volume24hView: MarketCardView
    private let deFiCapView: MarketCardView
    private let deFiTvlView: MarketCardView

    init(chartConfiguration: ChartConfiguration, presentDelegate: IPresentDelegate) {
        self.presentDelegate = presentDelegate

        totalMarketCapView = MarketCardView(configuration: chartConfiguration)
        volume24hView = MarketCardView(configuration: chartConfiguration)
        deFiCapView = MarketCardView(configuration: chartConfiguration)
        deFiTvlView = MarketCardView(configuration: chartConfiguration)

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        let scrollView = UIScrollView()

        contentView.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin12)
            make.top.bottom.equalToSuperview().inset(CGFloat.margin16)
        }

        scrollView.isPagingEnabled = true
        scrollView.clipsToBounds = false
        scrollView.showsHorizontalScrollIndicator = false

        let firstStack = UIStackView(arrangedSubviews: [totalMarketCapView, volume24hView])
        firstStack.spacing = .margin8
        firstStack.distribution = .fillEqually

        let secondStack = UIStackView(arrangedSubviews: [deFiCapView, deFiTvlView])
        secondStack.spacing = .margin8
        secondStack.distribution = .fillEqually

        let leadingView = UIView()
        let trailingView = UIView()

        let stackView = UIStackView(arrangedSubviews: [
            leadingView,
            firstStack,
            secondStack,
            trailingView,
        ])

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView).inset(-CGFloat.margin4)
            make.top.bottom.equalTo(scrollView)
            make.height.equalTo(scrollView)
        }

        stackView.spacing = .margin8

        leadingView.snp.makeConstraints { make in
            make.width.equalTo(0)
        }
        trailingView.snp.makeConstraints { make in
            make.width.equalTo(0)
        }
        firstStack.snp.makeConstraints { make in
            make.width.equalTo(scrollView).offset(-CGFloat.margin8)
        }
        secondStack.snp.makeConstraints { make in
            make.width.equalTo(scrollView).offset(-CGFloat.margin8)
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

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
