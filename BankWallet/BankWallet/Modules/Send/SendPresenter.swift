import Foundation

class SendPresenter {
    enum SendError: Error {
        case noAddress
        case noAmount
    }

    weak var view: ISendView?

    private let interactor: ISendInteractor
    private let router: ISendRouter
    private let factory: ISendConfirmationViewItemFactory

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let feeModule: ISendFeeModule

    private var sendInputType: SendInputType = .coin

    init(interactor: ISendInteractor, router: ISendRouter, factory: ISendConfirmationViewItemFactory, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule) {
        self.interactor = interactor
        self.router = router
        self.factory = factory

        self.amountModule = amountModule
        self.addressModule = addressModule
        self.feeModule = feeModule
    }

    private func updateModules() {
        var params = [String: Any]()
        params[AdapterField.amount.rawValue] = amountModule.coinAmount.value
        params[AdapterField.address.rawValue] = addressModule.address
        params[AdapterField.feeRateRriority.rawValue] = feeModule.feeRatePriority

        interactor.validate(params: params)
        interactor.updateFee(params: params)
    }

    private func updateSendButtonState() {
        let enabled = amountModule.validState && addressModule.validState && feeModule.validState

        view?.set(sendButtonEnabled: enabled)
    }

}

extension SendPresenter: ISendViewDelegate {

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func onViewDidLoad() {
        view?.set(coin: interactor.coin)
        updateModules()
    }

    func onClose() {
        view?.dismissKeyboard()
        router.dismiss()
    }

    func onCopyAddress() {
        guard let address = addressModule.address else {
            return
        }

        interactor.copy(address: address)
        view?.showCopied()
    }

    func onSendClicked() {
        do {
            let viewItem = try factory.confirmationViewItem(coin: interactor.coin, sendInputType: sendInputType, address: addressModule.address,
                    coinAmountValue: amountModule.coinAmount, currencyAmountValue: amountModule.fiatAmount,
                    coinFeeValue: feeModule.coinFee, currencyFeeValue: feeModule.fiatFee)
            view?.showConfirmation(viewItem: viewItem)
        } catch {
            view?.show(error: error)
        }
    }

    func onConfirmClicked() {
        guard let address = addressModule.address else {
            view?.show(error: SendError.noAddress)
            return
        }

        let amount = amountModule.coinAmount.value

        guard amount != 0 else {
            view?.show(error: SendError.noAmount)
            return
        }
        interactor.send(amount: amount, address: address, feeRatePriority: feeModule.feeRatePriority)
    }

}

extension SendPresenter: ISendInteractorDelegate {

    func didSend() {
        view?.dismissWithSuccess()
    }

    func didFailToSend(error: Error) {
        view?.show(error: error)
    }

    func onBecomeActive() {
//        interactor.retrieveRate()
    }

    func didValidate(with errors: [SendStateError]) {
        var amountValidationSuccess = true
        errors.forEach {
            switch($0) {
            case .insufficientAmount(availableBalance: let availableBalance):
                amountValidationSuccess = false
                amountModule.insufficientAmount(availableBalance: availableBalance)
            case .insufficientFeeBalance(fee: let fee):
                feeModule.insufficientFeeBalance(coinCode: interactor.coin.code, fee: fee)
            }
        }
        if amountValidationSuccess {
            amountModule.onValidationSuccess()
        }

        updateSendButtonState()
    }

    func didUpdate(fee: Decimal) {
        feeModule.update(fee: fee)
    }

}

extension SendPresenter: ISendAmountDelegate {

    var availableBalance: Decimal {
        var params = [String: Any]()
        params[AdapterField.address.rawValue] = addressModule.address
        params[AdapterField.feeRateRriority.rawValue] = feeModule.feeRatePriority
        do {
            return try interactor.availableBalance(params: params)
        } catch {
            //
        }
        return 0
    }

    func onChanged() {
        updateModules()
    }

    func onChanged(sendInputType: SendInputType) {
        self.sendInputType = sendInputType

        feeModule.update(sendInputType: sendInputType)
    }

}

extension SendPresenter: ISendAddressDelegate {

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        return interactor.parse(paymentAddress: paymentAddress)
    }

    func onAddressUpdate(address: String?) {
        updateModules()
    }

    func onAmountUpdate(amount: Decimal) {
        // todo:
    }

    func scanQrCode(delegate: IScanQrCodeDelegate) {
        router.scanQrCode(delegate: delegate)
    }

}

extension SendPresenter: ISendFeeDelegate {

    func updateFeeRate() {
        updateModules()
    }

}
