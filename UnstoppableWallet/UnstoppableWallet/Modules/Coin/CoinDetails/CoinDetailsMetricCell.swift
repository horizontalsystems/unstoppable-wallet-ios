import UIKit
import SnapKit
import ThemeKit
import HUD
import Chart
import ComponentKit

class CoinDetailsMetricCell: UITableViewCell {
    static let cellHeight: CGFloat = 104

    private let metricView = MarketMetricView()
    var onTap: (() -> ())? {
        didSet {
            metricView.onTap = onTap
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(metricView)
        metricView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(MarketMetricView.height)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension CoinDetailsMetricCell {

    func set(configuration: ChartConfiguration) {
        metricView.set(configuration: configuration)
    }

    var title: String? {
        get { metricView.title }
        set { metricView.title = newValue }
    }

    func set(viewItem: CoinDetailsViewModel.ChartViewItem) {
        metricView.badge = viewItem.badge
        metricView.set(
                value: viewItem.value,
                diff: viewItem.diff,
                chartData: viewItem.chartData,
                trend: viewItem.chartTrend
        )
    }

}
