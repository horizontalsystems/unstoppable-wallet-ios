import Chart
import SwiftUI
import UIKit

struct ChartView: UIViewRepresentable {
    typealias UIViewType = UIView

    let viewModel: IChartViewModel & IChartViewTouchDelegate
    let configuration: ChartConfiguration

    func makeUIView(context _: Context) -> UIView {
        let chartView = ChartUiView(viewModel: viewModel, configuration: configuration)
        chartView.setContentHuggingPriority(.required, for: .vertical)
        chartView.onLoad()
        return chartView
    }

    func updateUIView(_: UIView, context _: Context) {}
}

struct RateChartViewNew: UIViewRepresentable {
    typealias UIViewType = RateChartUiView

    let configuration: ChartConfiguration
    let trend: MovementTrend
    let data: ChartData

    func makeUIView(context _: Context) -> RateChartUiView {
        let chartView = RateChartUiView(configuration: configuration, trend: trend, data: data)
        chartView.setContentHuggingPriority(.required, for: .vertical)
        return chartView
    }

    func updateUIView(_ uiView: RateChartUiView, context _: Context) {
        uiView.update(trend: trend, data: data)
    }
}

class RateChartUiView: UIView {
    private static let height: CGFloat = 60

    private let chartView: RateChartView

    init(configuration: ChartConfiguration, trend: MovementTrend, data: ChartData) {
        chartView = RateChartView(configuration: configuration)
        chartView.setCurve(colorType: trend.chartColorType)
        chartView.set(chartData: data, animated: false)
        chartView.isUserInteractionEnabled = false

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(chartView)
        chartView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.height.equalTo(Self.height)
        }
    }

    func update(trend: MovementTrend, data: ChartData) {
        chartView.setCurve(colorType: trend.chartColorType)
        chartView.set(chartData: data, animated: false)
        chartView.isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.height)
    }
}
