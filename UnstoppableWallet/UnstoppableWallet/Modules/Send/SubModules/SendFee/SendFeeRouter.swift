import UIKit
import MarketKit

class SendFeeRouter {

    static func module(platformCoin: PlatformCoin) -> (UIView, ISendFeeModule) {
        let interactor = SendFeeInteractor(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, feeCoinProvider: App.shared.feeCoinProvider)
        let presenter = SendFeePresenter(platformCoin: platformCoin, interactor: interactor)
        let view = SendFeeView(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view

        return (view, presenter)
    }

}
