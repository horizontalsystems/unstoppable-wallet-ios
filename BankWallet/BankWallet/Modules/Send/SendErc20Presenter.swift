import Foundation

class SendErc20Presenter {
    weak var view: ISendView?

    private let interactor: ISendErc20Interactor
    private let router: ISendRouter
    private let confirmationFactory: ISendConfirmationItemFactory

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let feeModule: ISendFeeModule
    private let feeSliderModule: ISendFeeSliderModule

    init(interactor: ISendErc20Interactor, router: ISendRouter, confirmationFactory: ISendConfirmationItemFactory, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule, feeSliderModule: ISendFeeSliderModule) {
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

    private func syncFee() {
        feeModule.set(fee: interactor.fee(gasPrice: feeSliderModule.feeRate))
    }

}

extension SendErc20Presenter: ISendViewDelegate {

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func onViewDidLoad() {
        view?.set(coin: interactor.coin)
        amountModule.set(availableBalance: interactor.availableBalance)
        feeModule.set(availableFeeBalance: interactor.availableEthereumBalance)
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

extension SendErc20Presenter: ISendErc20InteractorDelegate {

    func didSend() {
        view?.dismissWithSuccess()
    }

    func didFailToSend(error: Error) {
        view?.show(error: error)
    }

}

extension SendErc20Presenter: ISendConfirmationDelegate {

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

extension SendErc20Presenter: ISendAmountDelegate {

    func onChangeAmount() {
        syncSendButton()
    }

    func onChange(inputType: SendInputType) {
        feeModule.update(inputType: inputType)
    }

}

extension SendErc20Presenter: ISendAddressDelegate {

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

extension SendErc20Presenter: ISendFeeDelegate {

    var inputType: SendInputType {
        return amountModule.inputType
    }

}

extension SendErc20Presenter: ISendFeeSliderDelegate {

    func onUpdate(feeRate: Int) {
        syncFee()
        syncSendButton()
    }

}
