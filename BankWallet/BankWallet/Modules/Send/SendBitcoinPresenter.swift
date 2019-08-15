import Foundation

class SendBitcoinPresenter {
    weak var view: ISendView?

    private let coin: Coin

    private let interactor: ISendBitcoinInteractor
    private let router: ISendRouter
    private let confirmationFactory: ISendConfirmationItemFactory

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let feeModule: ISendFeeModule
    private let feeSliderModule: ISendFeeSliderModule

    init(coin: Coin, interactor: ISendBitcoinInteractor, router: ISendRouter, confirmationFactory: ISendConfirmationItemFactory, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule, feeSliderModule: ISendFeeSliderModule) {
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
        view?.set(sendButtonEnabled: amountModule.validAmount != nil && addressModule.address != nil)
    }

    private func syncAvailableBalance() {
        interactor.fetchAvailableBalance(feeRate: feeSliderModule.feeRate, address: addressModule.address)
    }

    private func syncFee() {
        interactor.fetchFee(amount: amountModule.coinAmount.value, feeRate: feeSliderModule.feeRate, address: addressModule.address)
    }

}

extension SendBitcoinPresenter: ISendViewDelegate {

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

extension SendBitcoinPresenter: ISendBitcoinInteractorDelegate {

    func didSend() {
        view?.dismissWithSuccess()
    }

    func didFailToSend(error: Error) {
        view?.show(error: error)
    }

    func didFetch(availableBalance: Decimal) {
        amountModule.set(availableBalance: availableBalance)
        syncSendButton()
    }

    func didFetch(fee: Decimal) {
        feeModule.set(fee: fee)
    }

}

extension SendBitcoinPresenter: ISendConfirmationDelegate {

    func onSendClicked(memo: String?) {
        guard let address = addressModule.address else {
            return
        }

        guard let amount = amountModule.validAmount else {
            return
        }

        view?.showProgress()
        interactor.send(amount: amount, address: address, feeRate: feeSliderModule.feeRate)
    }

}

extension SendBitcoinPresenter: ISendAmountDelegate {

    func onChangeAmount() {
        syncFee()
        syncSendButton()
    }

    func onChange(inputType: SendInputType) {
        feeModule.update(inputType: inputType)
    }

}

extension SendBitcoinPresenter: ISendAddressDelegate {

    func validate(address: String) throws {
        try interactor.validate(address: address)
    }

    func onUpdateAddress() {
        syncAvailableBalance()
        syncFee()
    }

    func onUpdate(amount: Decimal) {
        amountModule.set(amount: amount)
    }

    func scanQrCode(delegate: IScanQrCodeDelegate) {
        router.scanQrCode(delegate: delegate)
    }

}

extension SendBitcoinPresenter: ISendFeeDelegate {

    var inputType: SendInputType {
        return amountModule.inputType
    }

}

extension SendBitcoinPresenter: ISendFeeSliderDelegate {

    func onUpdate(feeRate: Int) {
        syncAvailableBalance()
        syncFee()
    }

}
