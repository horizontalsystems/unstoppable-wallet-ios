import UIKit
import CoinKit

class SendFeeRouter {

    static func module(coin: Coin) -> (UIView, ISendFeeModule) {
        let interactor = SendFeeInteractor(rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit, feeCoinProvider: App.shared.feeCoinProvider)
        let presenter = SendFeePresenter(coin: coin, interactor: interactor)
        let view = SendFeeView(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view

        return (view, presenter)
    }

}
