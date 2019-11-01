import UIKit

class SendFeeRouter {

    static func module(coin: Coin) -> (UIView, ISendFeeModule) {
        let interactor = SendFeeInteractor(rateManager: App.shared.rateManager, currencyManager: App.shared.currencyManager, feeCoinProvider: App.shared.feeCoinProvider)
        let presenter = SendFeePresenter(coin: coin, interactor: interactor)
        let view = SendFeeView(delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

}
