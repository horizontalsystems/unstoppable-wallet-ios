import Foundation

class SendEthereumPresenter {
    weak var view: ISendView?

    private let coin: Coin

    private let interactor: ISendEthereumInteractor
    private let router: ISendRouter
    private let confirmationFactory: ISendConfirmationItemFactory

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let feeModule: ISendFeeModule
    private let feeSliderModule: ISendFeeSliderModule

    init(coin: Coin, interactor: ISendEthereumInteractor, router: ISendRouter, confirmationFactory: ISendConfirmationItemFactory, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule, feeSliderModule: ISendFeeSliderModule) {
        self.coin = coin

        self.interactor = interactor
        self.router = router
        self.confirmationFactory = confirmationFactory

        self.amountModule = amountModule
        self.addressModule = addressModule
        self.feeModule = feeModule
        self.feeSliderModule = feeSliderModule
    }

    private func syncSendButton() {
        view?.set(sendButtonEnabled: amountModule.validAmount != nil && addressModule.address != nil && feeModule.isValid)
    }

    private func syncAvailableBalance() {
        amountModule.set(availableBalance: interactor.availableBalance(gasPrice: feeSliderModule.feeRate))
    }

    private func syncFee() {
        feeModule.set(fee: interactor.fee(gasPrice: feeSliderModule.feeRate))
    }

}

extension SendEthereumPresenter: ISendViewDelegate {

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func onViewDidLoad() {
        view?.set(coin: coin)
        syncAvailableBalance()

        feeModule.set(availableFeeBalance: interactor.ethereumBalance)
        syncFee()
    }

    func onClose() {
        view?.dismissKeyboard()
        router.dismiss()
    }

    func onSendClicked() {
        guard let address = addressModule.address else {
            return
        }

        guard let item = confirmationFactory.viewItem(sendInputType: amountModule.inputType, coinAmountValue: amountModule.coinAmount,
                currencyAmountValue: amountModule.fiatAmount, receiver: address, showMemo: false, coinFeeValue: feeModule.coinValue,
                currencyFeeValue: feeModule.currencyValue, estimateTime: nil) else {
            return
        }

        router.showConfirmation(item: item, delegate: self)
    }

}

extension SendEthereumPresenter: ISendEthereumInteractorDelegate {

    func didSend() {
        view?.dismissWithSuccess()
    }

    func didFailToSend(error: Error) {
        view?.show(error: error)
    }

}

extension SendEthereumPresenter: ISendConfirmationDelegate {

    func onSendClicked(memo: String?) {
        guard let address = addressModule.address else {
            return
        }

        guard let amount = amountModule.validAmount else {
            return
        }

        view?.showProgress()
        interactor.send(amount: amount, address: address, gasPrice: feeSliderModule.feeRate)
    }

}

extension SendEthereumPresenter: ISendAmountDelegate {

    func onChangeAmount() {
        syncSendButton()
    }

    func onChange(inputType: SendInputType) {
        feeModule.update(inputType: inputType)
    }

}

extension SendEthereumPresenter: ISendAddressDelegate {

    func validate(address: String) throws {
        try interactor.validate(address: address)
    }

    func onUpdateAddress() {
        syncSendButton()
    }

    func onUpdate(amount: Decimal) {
        amountModule.set(amount: amount)
    }

    func scanQrCode(delegate: IScanQrCodeDelegate) {
        router.scanQrCode(delegate: delegate)
    }

}

extension SendEthereumPresenter: ISendFeeDelegate {

    var inputType: SendInputType {
        return amountModule.inputType
    }

}

extension SendEthereumPresenter: ISendFeeSliderDelegate {

    func onUpdate(feeRate: Int) {
        syncAvailableBalance()
        syncFee()
        syncSendButton()
    }

}
