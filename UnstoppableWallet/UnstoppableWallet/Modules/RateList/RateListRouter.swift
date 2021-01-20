import UIKit
import SafariServices

class RateListRouter {
    private weak var navigationRouter: INavigationRouter?

    init(navigationRouter: INavigationRouter) {
        self.navigationRouter = navigationRouter
    }

}

extension RateListRouter: IRateListRouter {

    func showChart(coinCode: String, coinTitle: String, coinType: CoinType?) {
        navigationRouter?.push(viewController: ChartRouter.module(launchMode: .partial(coinCode: coinCode, coinTitle: coinTitle, coinType: coinType)))
    }

    func open(link: String) {
        if let url = URL(string: link) {
            let configuration = SFSafariViewController.Configuration()
            configuration.entersReaderIfAvailable = true

            let safariViewController = SFSafariViewController(url: url, configuration: configuration)
            navigationRouter?.present(viewController: safariViewController)
        }
    }

}

extension RateListRouter {

    static func module(navigationRouter: INavigationRouter, additionalSafeAreaInsets: UIEdgeInsets = .zero) -> UIViewController {
        let currency = App.shared.currencyKit.baseCurrency

        let router = RateListRouter(navigationRouter: navigationRouter)
        let interactor = RateListInteractor(
                rateManager: App.shared.rateManager,
                walletManager: App.shared.walletManager,
                appConfigProvider: App.shared.appConfigProvider,
                postsManager: App.shared.rateManager
        )
        let presenter = RateListPresenter(currency: currency, interactor: interactor, router: router)

        let viewController = RateListViewController(delegate: presenter)
        viewController.additionalSafeAreaInsets = additionalSafeAreaInsets

        presenter.view = viewController
        interactor.delegate = presenter

        return viewController
    }

}
