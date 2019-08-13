import UIKit

class SendFeeRouter {

    static func module(coin: Coin, feeCoin: Coin, coinProtocol: String) -> (UIView, ISendFeeModule) {
        let interactor = SendFeeInteractor(rateStorage: App.shared.grdbStorage, currencyManager: App.shared.currencyManager)
        let presenter = SendFeePresenter(coin: coin, feeCoin: feeCoin, coinProtocol: coinProtocol, interactor: interactor)
        let view = SendFeeView(delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

    static func module(coin: Coin) -> (UIView, ISendFeeModule) {
        return module(coin: coin, feeCoin: coin, coinProtocol: "")
    }

}
