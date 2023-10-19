import Foundation
import SwiftUI
import ThemeKit
import UIKit

class ChartIndicatorRouter {
    private let repository: IChartIndicatorsRepository
    private let fetcher: IChartPointFetcher

    init(repository: IChartIndicatorsRepository, fetcher: IChartPointFetcher) {
        self.repository = repository
        self.fetcher = fetcher
    }

    func viewController() -> UIViewController {
        let service = ChartIndicatorsService(repository: repository, chartPointFetcher: fetcher, subscriptionManager: App.shared.subscriptionManager)
        let viewModel = ChartIndicatorsViewModel(service: service)

        return ThemeNavigationController(rootViewController: ChartIndicatorsViewController(viewModel: viewModel))
    }
}

enum ChartIndicatorsModule {
    static func view(repository: IChartIndicatorsRepository, fetcher: IChartPointFetcher) -> some View {
        let service = ChartIndicatorsService(repository: repository, chartPointFetcher: fetcher, subscriptionManager: App.shared.subscriptionManager)
        let viewModel = ChartIndicatorsViewModel(service: service)

        return ChartIndicatorsView(viewModel: viewModel)
    }
}

struct ChartIndicatorsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let viewModel: ChartIndicatorsViewModel

    func makeUIViewController(context _: Context) -> UIViewController {
        ThemeNavigationController(rootViewController: ChartIndicatorsViewController(viewModel: viewModel))
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
