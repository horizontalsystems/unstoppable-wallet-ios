import UIKit

class SendFeeRouter {

    static func module(coin: Coin) -> (UIView, ISendFeeModule) {
        let feeCoinData = App.shared.feeCoinProvider.feeCoinData(coin: coin)

        let interactor = SendFeeInteractor(rateStorage: App.shared.grdbStorage, currencyManager: App.shared.currencyManager)
        let presenter = SendFeePresenter(coin: coin, feeCoinData: feeCoinData, interactor: interactor)
        let view = SendFeeView(delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

}
