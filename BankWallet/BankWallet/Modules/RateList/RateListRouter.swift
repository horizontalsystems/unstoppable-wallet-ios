import UIKit

class RateListRouter {
}


extension RateListRouter: IRateListRouter {
}

extension RateListRouter {

    static func module() -> UIViewController {
        let router = RateListRouter()

        let coins = RateListSorter().smartSort(for: App.shared.walletManager.wallets.map { $0.coin }, featuredCoins: App.shared.appConfigProvider.featuredCoins)
        let dataSource = RateListDataSource(currency: App.shared.currencyManager.baseCurrency, coins: coins)
        let interactor = RateListInteractor(rateStatsManager: App.shared.rateStatsManager, appManager: App.shared.appManager, rateStorage: App.shared.storage, currentDateProvider: CurrentDateProvider())
        let presenter = RateListPresenter(interactor: interactor, router: router, dataSource: dataSource)

        let viewController = RateListViewController(delegate: presenter)

        presenter.view = viewController
        interactor.delegate = presenter

        return viewController
    }

}
