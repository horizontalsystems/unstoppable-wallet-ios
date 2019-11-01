import UIKit

class RateListRouter {
}


extension RateListRouter: IRateListRouter {
}

extension RateListRouter {

    static func module() -> UIViewController {
        let router = RateListRouter()

        let factory = RateListFactory(currentDateProvider: CurrentDateProvider())
        let interactor = RateListInteractor(rateManager: App.shared.xRateManager, currencyManager: App.shared.currencyManager, walletManager: App.shared.walletManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = RateListPresenter(interactor: interactor, router: router, rateListSorter: RateListSorter(), factory: factory)

        let viewController = RateListViewController(delegate: presenter)

        presenter.view = viewController
        interactor.delegate = presenter

        return viewController
    }

}
