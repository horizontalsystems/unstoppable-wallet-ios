import Foundation
import WalletKit
import RealmSwift

class SendPresenter {

    let interactor: ISendInteractor
    let router: ISendRouter
    weak var view: ISendView?

    init(interactor: ISendInteractor, router: ISendRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension SendPresenter: ISendInteractorDelegate {
    func didFetchExchangeRate(exchangeRate: Double) {
        print("didFetchExchangeRate")
    }

    func didFailToSend(error: Error) {
        print("didFailToSend")
    }

    func didSend() {
        print("didSend")
    }
}

extension SendPresenter: ISendViewDelegate {

    func onScanClick() {
        print("onScanClick")
    }

    func onPasteClick() {
        print("onPasteClick")
    }

    func onCurrencyButtonClick() {
        print("onCurrencyButtonClick")
    }

    func onViewDidLoad() {
        print("onViewDidLoad")
    }

    func onAmountEntered(amount: String?) {
        print("onAmountEntered")
    }

    func onCancelClick() {
        print("onCancelClick")
    }

    func onSendClick(address: String) {
        print("onSendClick")
    }

}
