import UIKit
import SnapKit
import ThemeKit
import RxSwift
import HUD

class MarketMetricsCell: UITableViewCell {
    private static let ellipseDiameter: CGFloat = 124
    static let cellHeight: CGFloat = 156 + 2 * .margin12

    private let viewModel: MarketMetricsViewModel
    private let disposeBag = DisposeBag()

    private let cardView = UIView()
    private let ellipseView = UIImageView()
    private let marketLargeView = MarketMetricLargeView()
    private let marketWrapperView = UIView()
    private let volume24hView = MarketMetricView()
    private let btcDominanceView = MarketMetricView()
    private let deFiCapView = MarketMetricView()
    private let deFiTvlView = MarketMetricView()

    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = ErrorView()

    init(viewModel: MarketMetricsViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin12)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        cardView.backgroundColor = .themeLawrence
        cardView.layer.cornerRadius = .cornerRadius4x
        cardView.clipsToBounds = true

        cardView.addSubview(ellipseView)
        ellipseView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(CGFloat.margin16)
            maker.size.equalTo(Self.ellipseDiameter)
        }

        ellipseView.image = UIImage(named: "ellipse_111")?.tinted(with: .themeTyler)

        cardView.addSubview(marketLargeView)
        marketLargeView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.width.equalTo(Self.ellipseDiameter).priority(.high)
        }

        cardView.addSubview(marketWrapperView)
        marketWrapperView.snp.makeConstraints { maker in
            maker.leading.greaterThanOrEqualTo(marketLargeView.snp.trailing).offset(CGFloat.margin12)
            maker.top.trailing.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.width.equalTo(172)
        }

        marketWrapperView.addSubview(volume24hView)
        volume24hView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview()
            maker.width.equalTo(MarketMetricView.width)
        }

        marketWrapperView.addSubview(btcDominanceView)
        btcDominanceView.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview()
            maker.leading.equalTo(volume24hView.snp.trailing).offset(CGFloat.margin16)
            maker.width.equalTo(MarketMetricView.width)
        }

        marketWrapperView.addSubview(deFiCapView)
        deFiCapView.snp.makeConstraints { maker in
            maker.leading.bottom.equalToSuperview()
            maker.width.equalTo(MarketMetricView.width)
        }

        marketWrapperView.addSubview(deFiTvlView)
        deFiTvlView.snp.makeConstraints { maker in
            maker.bottom.trailing.equalToSuperview()
            maker.width.equalTo(MarketMetricView.width)
        }

        cardView.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        cardView.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin16)
        }

        subscribe(disposeBag, viewModel.metricsDriver) { [weak self] in self?.sync(marketMetrics: $0) }
        subscribe(disposeBag, viewModel.isLoadingDriver) { [weak self] in self?.sync(isLoading: $0) }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] in self?.sync(error: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

        marketLargeView.set(title: "market.total_market_cap".localized,
                value: marketMetrics.totalMarketCap.value,
                diff: marketMetrics.totalMarketCap.diff
        )

        volume24hView.set(title: "market.24h_volume".localized,
                value: marketMetrics.volume24h.value,
                diff: marketMetrics.volume24h.diff
        )

        btcDominanceView.set(title: "market.btc_dominance".localized,
                value: marketMetrics.btcDominance.value,
                diff: marketMetrics.btcDominance.diff
        )

        deFiCapView.set(title: "market.defi_cap".localized,
                value: marketMetrics.defiCap.value,
                diff: marketMetrics.defiCap.diff
        )

        deFiTvlView.set(title: "market.defi_tvl".localized,
                value: marketMetrics.defiTvl.value,
                diff: marketMetrics.defiTvl.diff
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

extension MarketMetricsCell {

    func refresh() {
        viewModel.refresh()
    }

}
