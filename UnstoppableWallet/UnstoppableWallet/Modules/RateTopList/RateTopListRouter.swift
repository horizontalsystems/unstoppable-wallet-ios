import UIKit

class RateTopListRouter {
    private weak var chartOpener: IChartOpener?

    init(chartOpener: IChartOpener?) {
        self.chartOpener = chartOpener
    }

}

extension RateTopListRouter: IRateTopListRouter {

    func showChart(coinCode: String, coinTitle: String) {
        chartOpener?.showChart(coinCode: coinCode, coinTitle: coinTitle)
    }

}

extension RateTopListRouter {

    static func module(chartOpener: IChartOpener, additionalSafeAreaInsets: UIEdgeInsets = .zero) -> UIViewController {
        let currency = App.shared.currencyKit.baseCurrency

        let router = RateTopListRouter(chartOpener: chartOpener)
        let interactor = RateTopListInteractor(rateManager: App.shared.rateManager, walletManager: App.shared.walletManager)
        let presenter = RateTopListPresenter(currency: currency, interactor: interactor, router: router)

        let viewController = RateTopListViewController(delegate: presenter)
        viewController.additionalSafeAreaInsets = additionalSafeAreaInsets

        presenter.view = viewController
        interactor.delegate = presenter

        return viewController
    }

}
