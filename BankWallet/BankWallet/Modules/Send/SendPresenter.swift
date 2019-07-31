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

    private var amountModule: ISendAmountModule?
    private var addressModule: ISendAddressModule?
    private var feeModule: ISendFeeModule?

    private var sendInputType: SendInputType = .coin

    init(interactor: ISendInteractor, router: ISendRouter, factory: ISendConfirmationViewItemFactory) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
    }

    private func updateModules() {
        var params = [String: Any]()
        params[AdapterField.amount.rawValue] = amountModule?.coinAmount.value
        params[AdapterField.address.rawValue] = addressModule?.address
        params[AdapterField.feeRateRriority.rawValue] = feeModule?.feeRatePriority

        interactor.validate(params: params)
        interactor.updateFee(params: params)
    }

    private func updateSendButtonState() {
        let enabled =   (amountModule?.validState ?? false) &&
                        (addressModule?.validState ?? false) &&
                        (feeModule?.validState ?? false)

        view?.set(sendButtonEnabled: enabled)
    }

}

extension SendPresenter: ISendViewDelegate {

    func showKeyboard() {
        amountModule?.showKeyboard()
    }

    func onViewDidLoad() {
        view?.set(coin: interactor.coin)
        amountModule = view?.addAmountModule(coinCode: interactor.coin.code, decimal: interactor.decimal, delegate: self)
        addressModule = view?.addAddressModule(delegate: self)
        feeModule = view?.addFeeModule(coinCode: interactor.coin.code, decimal: interactor.decimal, delegate: self)
        view?.addSendButton()

        updateModules()
    }

    func onClose() {
        view?.dismissKeyboard()
        router.dismiss()
    }

    func onCopyAddress() {
        guard let address = addressModule?.address else {
            return
        }

        interactor.copy(address: address)
        view?.showCopied()
    }

    func onSendClicked() {
        guard let coinAmount = amountModule?.coinAmount,
              let coinFee = feeModule?.coinFee else {
            // todo: check modules existing!
            return
        }
        do {
            let viewItem = try factory.confirmationViewItem(coin: interactor.coin, sendInputType: sendInputType, address: addressModule?.address,
                    coinAmountValue: coinAmount, currencyAmountValue: amountModule?.fiatAmount,
                    coinFeeValue: coinFee, currencyFeeValue: feeModule?.fiatFee)
            view?.showConfirmation(viewItem: viewItem)
        } catch {
            view?.show(error: error)
        }
    }

    func onConfirmClicked() {
        guard let address = addressModule?.address else {
            view?.show(error: SendError.noAddress)
            return
        }

        guard let amount = amountModule?.coinAmount.value, amount != 0 else {
            view?.show(error: SendError.noAmount)
            return
        }
        interactor.send(amount: amount, address: address, feeRatePriority: feeModule?.feeRatePriority ?? .medium)
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
                amountModule?.insufficientAmount(availableBalance: availableBalance)
            case .insufficientFeeBalance(fee: let fee):
                feeModule?.insufficientFeeBalance(coinCode: interactor.coin.code, fee: fee)
            }
        }
        if amountValidationSuccess {
            amountModule?.onValidationSuccess()
        }

        updateSendButtonState()
    }

    func didUpdate(fee: Decimal) {
        feeModule?.update(fee: fee)
    }

}

extension SendPresenter: ISendAmountDelegate {

    var availableBalance: Decimal {
        var params = [String: Any]()
        params[AdapterField.address.rawValue] = addressModule?.address
        params[AdapterField.feeRateRriority.rawValue] = feeModule?.feeRatePriority
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

        feeModule?.update(sendInputType: sendInputType)
    }

}

extension SendPresenter: ISendAddressPresenterDelegate {

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        return interactor.parse(paymentAddress: paymentAddress)
    }

    func onAddressUpdate(address: String?) {
        updateModules()
    }

    func onAmountUpdate(amount: Decimal) {
        // todo:
    }

}

extension SendPresenter: ISendFeePresenterDelegate {

    func updateFeeRate() {
        updateModules()
    }

}