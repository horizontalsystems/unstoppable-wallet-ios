import SwiftUI
import ThemeKit

struct MarketGlobalMetricsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let metricsType: MarketGlobalModule.MetricsType

    func makeUIViewController(context _: Context) -> UIViewController {
        MarketGlobalMetricModule.viewController(type: metricsType)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
