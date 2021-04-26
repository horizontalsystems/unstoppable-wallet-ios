import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class ChartMarketPerformanceCell: BaseThemeCell {
    private let weekPerformanceView = MultiTextMetricsView()
    private let monthPerformanceView = MultiTextMetricsView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        wrapperView.addSubview(weekPerformanceView)
        weekPerformanceView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview()
        }

        weekPerformanceView.title = "chart.performance.week_changes".localized

        wrapperView.addSubview(monthPerformanceView)
        monthPerformanceView.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview()
            maker.leading.equalTo(weekPerformanceView.snp.trailing).offset(CGFloat.margin8)
            maker.width.equalTo(weekPerformanceView)
        }

        monthPerformanceView.title = "chart.performance.month_changes".localized
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(weekPerformance: [MultiTextMetricsView.MetricsViewItem], monthPerformance: [MultiTextMetricsView.MetricsViewItem]) {
        weekPerformanceView.metricsViewItems = weekPerformance
        monthPerformanceView.metricsViewItems = monthPerformance
    }

    static func cellHeight(weekPerformance: [MultiTextMetricsView.MetricsViewItem], monthPerformance: [MultiTextMetricsView.MetricsViewItem]) -> CGFloat {
        max(MultiTextMetricsView.viewHeight(viewItems: weekPerformance), MultiTextMetricsView.viewHeight(viewItems: monthPerformance))
    }

}
