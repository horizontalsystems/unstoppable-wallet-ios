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
        let service = ChartIndicatorsService(repository: repository, chartPointFetcher: fetcher)
        let viewModel = ChartIndicatorsViewModel(service: service)

        return ThemeNavigationController(rootViewController: ChartIndicatorsViewController(viewModel: viewModel))
    }

}

class ChartIndicatorsModule {

    static func viewController(repository: ChartIndicatorsRepository, fetcher: IChartPointFetcher) -> ChartIndicatorsViewController {
        let service = ChartIndicatorsService(repository: repository, chartPointFetcher: fetcher)
        let viewModel = ChartIndicatorsViewModel(service: service)

        return ChartIndicatorsViewController(viewModel: viewModel)
    }

}
