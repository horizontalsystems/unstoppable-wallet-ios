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
