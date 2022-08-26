import UIKit
import SnapKit
import Chart
import ThemeKit
import ComponentKit

class ChartMarketCardView: MarketCardView {
    private static let configuration: ChartConfiguration = .chartPreview
    override class func viewHeight() -> CGFloat { MarketCardView.viewHeight() + .margin8 + ChartMarketCardView.configuration.mainHeight }

    private let chartView = RateChartView()

    var alreadyHasData: Bool = false

    required init() {
        super.init()

        commonInit()
    }

    private func commonInit() {
        stackView.addArrangedSubview(chartView)
        chartView.isUserInteractionEnabled = false

        chartView.snp.remakeConstraints { maker in
            maker.height.equalTo(Self.configuration.mainHeight)
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func set(viewItem: MarketCardView.ViewItem) {
        super.set(viewItem: viewItem)

        guard let viewItem = viewItem as? ChartMarketCardView.ViewItem else {
            return
        }
        chartView.apply(configuration: Self.configuration)

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

        override var viewType: MarketCardView.Type {
            ChartMarketCardView.self
        }
    }

}
