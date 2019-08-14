import Foundation

class SendEosPresenter {
    weak var view: ISendView?

    private let coin: Coin

    private let interactor: ISendEosInteractor
    private let router: ISendRouter
    private let confirmationFactory: ISendConfirmationItemFactory

    private let amountModule: ISendAmountModule
    private let accountModule: ISendAccountModule

    init(coin: Coin, interactor: ISendEosInteractor, router: ISendRouter, confirmationFactory: ISendConfirmationItemFactory, amountModule: ISendAmountModule, accountModule: ISendAccountModule) {
        self.coin = coin

        self.interactor = interactor
        self.router = router
        self.confirmationFactory = confirmationFactory

        self.amountModule = amountModule
        self.accountModule = accountModule
    }

    private func syncSendButton() {
        view?.set(sendButtonEnabled: amountModule.validAmount != nil && accountModule.account != nil)
    }

    private func syncAvailableBalance() {
        amountModule.set(availableBalance: interactor.availableBalance)
    }

}

extension SendEosPresenter: ISendViewDelegate {

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func onViewDidLoad() {
        view?.set(coin: coin)
        syncAvailableBalance()
    }

    func onClose() {
        view?.dismissKeyboard()
        router.dismiss()
    }

    func onSendClicked() {
        guard let account = accountModule.account else {
            return
        }

        guard let item = confirmationFactory.viewItem(sendInputType: amountModule.inputType, coinAmountValue: amountModule.coinAmount,
                currencyAmountValue: amountModule.fiatAmount, receiver: account, showMemo: true, coinFeeValue: nil,
                currencyFeeValue: nil, estimateTime: nil) else {
            return
        }

        router.showConfirmation(item: item, delegate: self)
    }

}

extension SendEosPresenter: ISendEosInteractorDelegate {

    func didSend() {
        view?.dismissWithSuccess()
    }

    func didFailToSend(error: Error) {
        view?.show(error: error)
    }

}

extension SendEosPresenter: ISendConfirmationDelegate {

    func onSendClicked(memo: String?) {
        guard let account = accountModule.account else {
            return
        }

        guard let amount = amountModule.validAmount else {
            return
        }

        view?.showProgress()
        interactor.send(amount: amount, account: account, memo: memo)
    }

}

extension SendEosPresenter: ISendAmountDelegate {

    func onChangeAmount() {
        syncSendButton()
    }

    func onChange(inputType: SendInputType) {
    }

}

extension SendEosPresenter: ISendAccountDelegate {

    func validate(account: String) throws {
        try interactor.validate(account: account)
    }

    func onUpdateAccount() {
        syncSendButton()
    }

    func scanQrCode(delegate: IScanQrCodeDelegate) {
        router.scanQrCode(delegate: delegate)
    }

}
