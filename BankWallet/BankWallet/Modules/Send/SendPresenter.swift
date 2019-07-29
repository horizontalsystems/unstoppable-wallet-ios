import Foundation

class SendPresenter {
    weak var view: ISendView?

    private let interactor: ISendInteractor
    private let router: ISendRouter

    var amountModule: ISendAmountModule!
    var addressModule: ISendAddressModule!
    var feeModule: ISendFeeModule!

    init(interactor: ISendInteractor, router: ISendRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func updateModules() {
        var params = [String: Any]()
        params[AdapterFields.amount.rawValue] = amountModule.coinAmount ?? Decimal(0)
        params[AdapterFields.address.rawValue] = addressModule.address
        params[AdapterFields.feeRateRriority.rawValue] = feeModule.feeRatePriority

        interactor.validate(params: params)
        interactor.updateFee(params: params)
    }
}

extension SendPresenter: ISendViewDelegate {

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func onViewDidLoad() {
        view?.set(coin: interactor.coin)
        view?.build(modules: [amountModule, addressModule, feeModule])

        updateModules()
    }

    func onClose() {
        view?.dismissKeyboard()
        router.dismiss()
    }

    func onConfirmClicked() {
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
            case .insufficientAmount:
                amountValidationSuccess = false
                amountModule.onValidation(error: $0)
            case .insufficientFeeBalance(fee: let fee):
                feeModule.insufficientFeeBalance(coinCode: interactor.coin.code, fee: fee)
            }
        }
        if amountValidationSuccess {
            amountModule.onValidationSuccess()
        }
    }

    func didUpdate(fee: Decimal) {
        feeModule.update(fee: fee)
    }

}

extension SendPresenter: ISendAmountPresenterDelegate {

    var availableBalance: Decimal {
        var params = [String: Any]()
        params[AdapterFields.address.rawValue] = addressModule.address
        params[AdapterFields.feeRateRriority.rawValue] = feeModule.feeRatePriority
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
        feeModule.update(sendInputType: sendInputType)
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

    func updateFee() {
        updateModules()
    }

}