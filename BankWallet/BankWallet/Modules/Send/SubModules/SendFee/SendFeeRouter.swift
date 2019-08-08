import UIKit

class SendFeeRouter {
}

extension SendFeeRouter {

    static func module(feeCoinCode: CoinCode, coinProtocol: String = "ERC20", baseCoinName: String = "Ethereum", decimal: Int) -> (UIView, ISendFeeModule) {

        let interactor = SendFeeInteractor(rateStorage: App.shared.grdbStorage)

        let formatHelper = SendFormatHelper(coinCode: feeCoinCode, coinDecimal: decimal, currencyManager: App.shared.currencyManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = SendFeePresenter(interactor: interactor, formatHelper: formatHelper, currencyManager: App.shared.currencyManager, coinCode: feeCoinCode, coinProtocol: coinProtocol, baseCoinName: baseCoinName)
        let view = SendFeeView(delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

}