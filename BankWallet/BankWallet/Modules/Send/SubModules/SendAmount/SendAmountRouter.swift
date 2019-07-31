import UIKit

class SendAmountRouter {

    static func module(coinCode: CoinCode, decimal: Int) -> (UIView, ISendAmountModule) {
        let interactor = SendAmountInteractor(appConfigProvider: App.shared.appConfigProvider, localStorage: App.shared.localStorage, rateStorage: App.shared.grdbStorage)

        let sendAmountPresenterHelper = SendFormatHelper(coinCode: coinCode, coinDecimal: decimal, currencyManager: App.shared.currencyManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = SendAmountPresenter(interactor: interactor, formatHelper: sendAmountPresenterHelper, currencyManager: App.shared.currencyManager, coinCode: coinCode, coinDecimal: decimal)
        let sendView = SendAmountView(delegate: presenter)

        presenter.view = sendView

        return (sendView, presenter)
    }

}
