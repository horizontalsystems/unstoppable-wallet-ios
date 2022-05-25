import UIKit
import SnapKit
import Chart
import ThemeKit
import ComponentKit

class ChartMarketCardView: MarketCardView {
    override class func viewHeight() -> CGFloat { MarketCardView.viewHeight() + .margin8 + ChartConfiguration.chartPreview.mainHeight }

    private let chartView = RateChartView()
    private var configuration: ChartConfiguration?

    var alreadyHasData: Bool = false

    required init() {
        super.init()

        commonInit()
    }

    required init(configuration: ChartConfiguration?) {
        self.configuration = configuration
        super.init()

        commonInit()
    }

    private func commonInit() {
        stackView.addArrangedSubview(chartView)

        if let configuration = configuration {
            chartView.apply(configuration: configuration)
            chartView.snp.makeConstraints { maker in
                maker.height.equalTo(configuration.mainHeight)
            }
        }

        chartView.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func set(configuration: ChartConfiguration) {
        self.configuration = configuration
        chartView.apply(configuration: configuration)
        chartView.snp.remakeConstraints { maker in
            maker.height.equalTo(configuration.mainHeight)
        }
    }

    override func set(viewItem: MarketCardView.ViewItem) {
        super.set(viewItem: viewItem)

        guard let viewItem = viewItem as? ChartMarketCardView.ViewItem else {
            return
        }

        let colorType: ChartColorType
        switch viewItem.trend {
        case .neutral: colorType = .neutral
        case .up: colorType = .up
        case .down: colorType = .down
        }

        chartView.setCurve(colorType: colorType)
        if let chartData = viewItem.data {
            chartView.set(chartData: chartData, animated: alreadyHasData)
            alreadyHasData = true
        } else {
            alreadyHasData = false
            // clear
        }
    }

}


extension ChartMarketCardView {

    class ViewItem: MarketCardView.ViewItem {
        let data: ChartData?
        let trend: MovementTrend

        init(title: String?, value: String?, diff: String?, diffColor: UIColor?, data: ChartData?, trend: MovementTrend) {
            self.data = data
            self.trend = trend

            super.init(title: title, value: value, diff: diff, diffColor: diffColor)
        }

    }

}
