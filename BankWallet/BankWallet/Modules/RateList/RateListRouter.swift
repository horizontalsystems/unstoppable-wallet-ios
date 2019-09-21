import UIKit

class RateListRouter {
}


extension RateListRouter: IRateListRouter {
}

extension RateListRouter {

    static func module() -> UIViewController {
        let router = RateListRouter()

        let interactor = RateListInteractor(rateStatsManager: App.shared.rateStatsManager, appManager: App.shared.appManager, currencyManager: App.shared.currencyManager, walletManager: App.shared.walletManager, rateStorage: App.shared.storage, appConfigProvider: App.shared.appConfigProvider, rateListSorter: RateListSorter(), currentDateProvider: CurrentDateProvider())
        let presenter = RateListPresenter(interactor: interactor, router: router, dataSource: RateListDataSource())

        let viewController = RateListViewController(delegate: presenter)

        presenter.view = viewController
        interactor.delegate = presenter

        return viewController
    }

}
