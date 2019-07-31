import UIKit

class SendFeeRouter {
}

extension SendFeeRouter {

    static func module(coinCode: CoinCode, decimal: Int) -> (UIView, ISendFeeModule) {

        let interactor = SendFeeInteractor(rateStorage: App.shared.grdbStorage)

        let formatHelper = SendFormatHelper(coinCode: coinCode, coinDecimal: decimal, currencyManager: App.shared.currencyManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = SendFeePresenter(interactor: interactor, formatHelper: formatHelper, currencyManager: App.shared.currencyManager, coinCode: coinCode)
        let view = SendFeeView(feeAdjustable: true, delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

}