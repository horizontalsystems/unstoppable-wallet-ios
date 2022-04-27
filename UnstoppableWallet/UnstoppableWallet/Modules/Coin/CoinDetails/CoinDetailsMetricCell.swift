import UIKit
import SnapKit
import ThemeKit
import HUD
import Chart
import ComponentKit

class CoinDetailsMetricCell: UITableViewCell {
    static let cellHeight: CGFloat = 104

    private let leftMetricView = MarketMetricView()
    var onTapLeft: (() -> ())? {
        didSet {
            leftMetricView.onTap = onTapLeft
        }
    }

    private let rightMetricView = MarketMetricView()
    var onTapRight: (() -> ())? {
        didSet {
            rightMetricView.onTap = onTapRight
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(leftMetricView)
        leftMetricView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(MarketMetricView.height)
        }

        contentView.addSubview(rightMetricView)
        rightMetricView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalTo(leftMetricView.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(MarketMetricView.height)
            maker.width.equalTo(leftMetricView.snp.width)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateConstraints(hasLeft: Bool, hasRight: Bool) {
        let leftOnly = hasLeft && !hasRight
        let rightOnly = !hasLeft && hasRight

        leftMetricView.snp.remakeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            if leftOnly {
                maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            }
            maker.height.equalTo(MarketMetricView.height)
        }
        rightMetricView.snp.remakeConstraints { maker in
            maker.top.equalToSuperview()
            if rightOnly {
                maker.leading.equalToSuperview().inset(CGFloat.margin16)
            } else {
                maker.leading.equalTo(leftMetricView.snp.trailing).offset(CGFloat.margin8)
                maker.width.equalTo(leftMetricView.snp.width)
            }
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(MarketMetricView.height)
        }

        leftMetricView.isHidden = !hasLeft
        rightMetricView.isHidden = !hasRight
    }
}

extension CoinDetailsMetricCell {

    func set(configuration: ChartConfiguration) {
        leftMetricView.set(configuration: configuration)
        rightMetricView.set(configuration: configuration)
    }

    var leftTitle: String? {
        get { leftMetricView.title }
        set { leftMetricView.title = newValue }
    }

    var rightTitle: String? {
        get { rightMetricView.title }
        set { rightMetricView.title = newValue }
    }

    func set(leftViewItem: CoinDetailsViewModel.ChartViewItem? = nil, rightViewItem: CoinDetailsViewModel.ChartViewItem? = nil) {
        updateConstraints(hasLeft: leftViewItem != nil, hasRight: rightViewItem != nil)

        if let leftViewItem = leftViewItem {
            leftMetricView.set(
                    value: leftViewItem.value,
                    diff: leftViewItem.diff,
                    diffColor: leftViewItem.diffColor,
                    chartData: leftViewItem.chartData,
                    trend: leftViewItem.chartTrend
            )
        }
        if let rightViewItem = rightViewItem {
            rightMetricView.set(
                    value: rightViewItem.value,
                    diff: rightViewItem.diff,
                    diffColor: rightViewItem.diffColor,
                    chartData: rightViewItem.chartData,
                    trend: rightViewItem.chartTrend
            )
        }
    }

}
