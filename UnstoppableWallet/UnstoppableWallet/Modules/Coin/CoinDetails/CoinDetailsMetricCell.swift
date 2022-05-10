import UIKit
import SnapKit
import ThemeKit
import HUD
import Chart
import ComponentKit

class CoinDetailsMetricCell: UITableViewCell {
    static let cellHeight: CGFloat = 104

    private let stackView = UIStackView()
    private var configuration: ChartConfiguration?
    private var metricViews = [MarketMetricView]()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(MarketMetricView.height)
        }

        stackView.insetsLayoutMarginsFromSafeArea = false
        stackView.axis = .horizontal
        stackView.spacing = .margin8
        stackView.distribution = .fillEqually
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension CoinDetailsMetricCell {

    func set(configuration: ChartConfiguration) {
        self.configuration = configuration
        metricViews.forEach { view in view.set(configuration: configuration) }
    }

    func set(title: String?, index: Int? = nil) {
        guard let index = index else {
            metricViews.last?.title = title
            return
        }

        guard index < metricViews.count else {
            return
        }

        metricViews[index].title = title
    }

    func append(viewItem: CoinDetailsViewModel.ChartViewItem, onTap: (() -> ())? = nil) {
        let metricView = MarketMetricView(configuration: configuration)
        metricView.onTap = onTap

        metricView.set(
                value: viewItem.value,
                diff: viewItem.diff,
                diffColor: viewItem.diffColor,
                chartData: viewItem.chartData,
                trend: viewItem.chartTrend
        )

        metricViews.append(metricView)
        stackView.addArrangedSubview(metricView)
    }

    func remove(at index: Int) {
        guard index < metricViews.count else {
            return
        }

        stackView.removeArrangedSubview(metricViews[index])
        metricViews.remove(at: index)
    }

    func set(hidden: Bool, at index: Int) {
        guard index < metricViews.count else {
            return
        }

        metricViews[index].isHidden = hidden
    }

    func clear() {
        metricViews.forEach { view in
            stackView.removeArrangedSubview(view)
        }

        metricViews.removeAll()
    }

}
