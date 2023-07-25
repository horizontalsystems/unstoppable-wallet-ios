import Foundation
import UIKit
import ThemeKit

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
