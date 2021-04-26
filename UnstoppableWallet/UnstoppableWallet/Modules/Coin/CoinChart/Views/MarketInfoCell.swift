import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class MarketInfoCell: BaseThemeCell {
    public static let cellHeight: CGFloat = 152

    private let marketCapValueView = MultiTextMetricsView()
    private let volumeValueView = MultiTextMetricsView()
    private let circulationValueView = MultiTextMetricsView()
    private let totalSupplyValueView = MultiTextMetricsView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        wrapperView.addSubview(marketCapValueView)
        marketCapValueView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview()
        }

        marketCapValueView.title = "chart.market.market_cap".localized

        wrapperView.addSubview(volumeValueView)
        volumeValueView.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview()
            maker.leading.equalTo(marketCapValueView.snp.trailing).offset(CGFloat.margin8)
            maker.size.equalTo(marketCapValueView)
        }

        volumeValueView.title = "chart.market.volume".localized

        wrapperView.addSubview(circulationValueView)
        circulationValueView.snp.makeConstraints { maker in
            maker.leading.bottom.equalToSuperview()
            maker.top.equalTo(marketCapValueView.snp.bottom)
            maker.size.equalTo(marketCapValueView)
        }

        circulationValueView.title = "chart.market.circulation".localized

        wrapperView.addSubview(totalSupplyValueView)
        totalSupplyValueView.snp.makeConstraints { maker in
            maker.bottom.trailing.equalToSuperview()
            maker.top.equalTo(marketCapValueView.snp.bottom)
            maker.leading.equalTo(circulationValueView.snp.trailing).offset(CGFloat.margin8)
            maker.size.equalTo(marketCapValueView)
        }

        totalSupplyValueView.title = "chart.market.total_supply".localized
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(marketCap: String?, marketCapChange: String?, volume: String?, circulation: String?, totalSupply: String?) {
        marketCapValueView.metricsViewItems = [
            MultiTextMetricsView.MetricsViewItem(
                    value: marketCap,
                    valueChange: marketCapChange,
                    valueChangeColor: (marketCapChange?.contains("-") ?? true) ? .themeRedD : .themeRemus)]

        volumeValueView.metricsViewItems = [MultiTextMetricsView.MetricsViewItem(value: volume)]
        circulationValueView.metricsViewItems = [MultiTextMetricsView.MetricsViewItem(value: circulation)]
        totalSupplyValueView.metricsViewItems = [MultiTextMetricsView.MetricsViewItem(value: totalSupply)]
    }

}
