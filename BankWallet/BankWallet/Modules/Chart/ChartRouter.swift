import UIKit
import ActionSheet

class ChartRouter {

    static func module(coinCode: CoinCode) -> ActionSheetController? {
        guard let wallet = App.shared.walletManager.wallets.first(where: { $0.coin.code == coinCode }) else {
            return nil
        }

        let chartRateFactory = ChartRateFactory()
        let interactor = ChartInteractor(rateManager: App.shared.xRateManager, chartTypeStorage: App.shared.localStorage)
        let presenter = ChartPresenter(interactor: interactor, factory: chartRateFactory, coin: wallet.coin, currency: App.shared.currencyManager.baseCurrency)
        let viewController = ChartViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController

        return viewController
    }

}
