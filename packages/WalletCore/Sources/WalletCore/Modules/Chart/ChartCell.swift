import Chart
import SnapKit
import UIKit

class ChartCell: UITableViewCell {
    private let chartView: ChartUiView

    init(viewModel: IChartViewModel & IChartViewTouchDelegate, configuration: ChartConfiguration) {
        chartView = ChartUiView(viewModel: viewModel, configuration: configuration)

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(chartView)
        chartView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var cellHeight: CGFloat {
        chartView.totalHeight
    }
}

extension ChartCell {
    func onLoad() {
        chartView.onLoad()
    }
}
