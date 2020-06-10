import UIKit

class RateListRouter {
    private weak var navigationRouter: INavigationRouter?

    init(navigationRouter: INavigationRouter) {
        self.navigationRouter = navigationRouter
    }

}

extension RateListRouter: IRateListRouter {

    func showChart(coinCode: String, coinTitle: String) {
        navigationRouter?.push(viewController: ChartRouter.module(coinCode: coinCode, coinTitle: coinTitle))
    }

}

extension RateListRouter {

    static func module(navigationRouter: INavigationRouter, additionalSafeAreaInsets: UIEdgeInsets = .zero) -> UIViewController {
        let currency = App.shared.currencyKit.baseCurrency

        let router = RateListRouter(navigationRouter: navigationRouter)
        let interactor = RateListInteractor(rateManager: App.shared.rateManager, walletManager: App.shared.walletManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = RateListPresenter(currency: currency, interactor: interactor, router: router)

        let viewController = RateListViewController(delegate: presenter)
        viewController.additionalSafeAreaInsets = additionalSafeAreaInsets

        presenter.view = viewController
        interactor.delegate = presenter

        return viewController
    }

}
