import UIKit

class SendAmountRouter {

    static func module(coin: Coin) -> (UIView, ISendAmountModule) {
        let interactor = SendAmountInteractor(localStorage: App.shared.localStorage, rateStorage: App.shared.grdbStorage, currencyManager: App.shared.currencyManager)
        let presenter = SendAmountPresenter(coin: coin, interactor: interactor)
        let sendView = SendAmountView(delegate: presenter)

        presenter.view = sendView

        return (sendView, presenter)
    }

}
