import UIKit
import CoinKit

class SendAmountRouter {

    static func module(coin: Coin) -> (UIView, ISendAmountModule) {
        let decimalParser = AmountDecimalParser()
        let interactor = SendAmountInteractor(localStorage: App.shared.localStorage, rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit)
        let presenter = SendAmountPresenter(coin: coin, interactor: interactor, decimalParser: decimalParser)
        let sendView = SendAmountView(delegate: presenter)

        presenter.view = sendView

        return (sendView, presenter)
    }

}
