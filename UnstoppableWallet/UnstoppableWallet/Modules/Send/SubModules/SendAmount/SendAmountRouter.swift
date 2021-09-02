import UIKit
import MarketKit

class SendAmountRouter {

    static func module(platformCoin: PlatformCoin) -> (UIView, ISendAmountModule) {
        let decimalParser = AmountDecimalParser()
        let interactor = SendAmountInteractor(localStorage: App.shared.localStorage, rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit)
        let presenter = SendAmountPresenter(platformCoin: platformCoin, interactor: interactor, decimalParser: decimalParser)
        let sendView = SendAmountView(delegate: presenter)

        presenter.view = sendView

        return (sendView, presenter)
    }

}
