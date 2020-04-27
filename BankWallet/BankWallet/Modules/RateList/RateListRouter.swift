import UIKit

class RateListRouter {
    weak var delegate: IRateListDelegate?
}

extension RateListRouter: IRateListRouter {

    func showChart(coinCode: String, coinTitle: String) {
        delegate?.showChart(coinCode: coinCode, coinTitle: coinTitle)
    }

}

extension RateListRouter {

    static func module(delegate: IRateListDelegate, topMargin: CGFloat = 0) -> UIViewController {
        let router = RateListRouter()

        let factory = RateListFactory(currentDateProvider: CurrentDateProvider())
        let interactor = RateListInteractor(rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit, walletManager: App.shared.walletManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = RateListPresenter(interactor: interactor, router: router, rateListSorter: RateListSorter(), factory: factory)

        let viewController = RateListViewController(delegate: presenter, topMargin: topMargin)

        presenter.view = viewController
        interactor.delegate = presenter
        router.delegate = delegate

        return viewController
    }

}
