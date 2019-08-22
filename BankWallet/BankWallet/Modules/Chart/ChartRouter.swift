import UIKit
import ActionSheet

class ChartRouter {

    static func module(coinCode: CoinCode) -> ActionSheetController? {
        guard let wallet = App.shared.walletManager.wallets.first(where: { $0.coin.code == coinCode }) else {
            return nil
        }

        let chartRateConverter = ChartRateDataConverter()
        let interactor = ChartInteractor(apiProvider: App.shared.chartApiProvider, localStorage: App.shared.localStorage, rateStorage: App.shared.grdbStorage)
        let presenter = ChartPresenter(interactor: interactor, chartRateConverter: chartRateConverter, coin: wallet.coin, currency: App.shared.currencyManager.baseCurrency)
        let viewController = ChartViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController

        return viewController
    }

}
