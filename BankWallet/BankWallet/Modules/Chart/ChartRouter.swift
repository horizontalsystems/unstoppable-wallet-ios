import UIKit
import ThemeKit
import Chart
import SafariServices

class ChartRouter {
    weak var viewController: UIViewController?
}

extension ChartRouter: IChartRouter {

    func open(link: String) {
        if let url = URL(string: link) {
            let configuration = SFSafariViewController.Configuration()
            configuration.entersReaderIfAvailable = true

            let vc = SFSafariViewController(url: url, configuration: configuration)
            viewController?.present(vc, animated: true)
        }
    }

}

extension ChartRouter {

    static func module(coin: Coin) -> UIViewController {
        let router = ChartRouter()
        let chartRateFactory = ChartRateFactory()
        let interactor = ChartInteractor(rateManager: App.shared.rateManager, postsManager: App.shared.rateManager, chartTypeStorage: App.shared.localStorage, currentDateProvider: CurrentDateProvider())
        let presenter = ChartPresenter(interactor: interactor, router: router, factory: chartRateFactory, coin: coin, currency: App.shared.currencyKit.baseCurrency)
        let viewController = ChartViewController(delegate: presenter, chartConfiguration: ChartConfiguration.fullChart(currency: App.shared.currencyKit.baseCurrency))

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}
