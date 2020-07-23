import UIKit

class RateTopListRouter {
    private weak var navigationRouter: INavigationRouter?

    init(navigationRouter: INavigationRouter) {
        self.navigationRouter = navigationRouter
    }

}

extension RateTopListRouter: IRateTopListRouter {

    func showChart(coin: Coin) {
        navigationRouter?.push(viewController: ChartRouter.module(coin: coin))
    }

    func showSortType(selected: RateTopListModule.SortType, onSelect: @escaping (RateTopListModule.SortType) -> ()) {
        let sortTypes = RateTopListModule.SortType.allCases

        let alertController = AlertRouter.module(
                title: "top100_list.sort_by".localized,
                viewItems: sortTypes.map { sortType in
                    AlertViewItem(text: sortType.title, selected: sortType == selected)
                }
        ) { index in
            onSelect(sortTypes[index])
        }

        navigationRouter?.present(viewController: alertController)
    }

}

extension RateTopListRouter {

    static func module(navigationRouter: INavigationRouter, additionalSafeAreaInsets: UIEdgeInsets = .zero) -> UIViewController {
        let currency = App.shared.currencyKit.baseCurrency

        let router = RateTopListRouter(navigationRouter: navigationRouter)
        let interactor = RateTopListInteractor(rateManager: App.shared.rateManager, walletManager: App.shared.walletManager, coinManager: App.shared.coinManager)
        let presenter = RateTopListPresenter(currency: currency, interactor: interactor, router: router)

        let viewController = RateTopListViewController(delegate: presenter)
        viewController.additionalSafeAreaInsets = additionalSafeAreaInsets

        presenter.view = viewController
        interactor.delegate = presenter

        return viewController
    }

}
