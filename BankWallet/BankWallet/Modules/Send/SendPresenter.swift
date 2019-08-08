//import Foundation
//
//
//class SendPresenter {
//    weak var view: ISendView?
//    private let showMemo: Bool
//
//    private let interactor: ISendInteractor
//    private let router: ISendRouter
//    private let factory: ISendConfirmationItemFactory
//
//    private let amountModule: ISendAmountModule
//    private let addressModule: ISendAddressModule
//    private let feeModule: ISendFeeModule
//
//    private var sendInputType: SendInputType = .coin
//
//    init(interactor: ISendInteractor, router: ISendRouter, factory: ISendConfirmationItemFactory, showMemo: Bool = false, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule) {
//        self.interactor = interactor
//        self.router = router
//        self.factory = factory
//
//        self.showMemo = showMemo
//
//        self.amountModule = amountModule
//        self.addressModule = addressModule
//        self.feeModule = feeModule
//    }
//
//    private func updateModules() {
//        var params = [String: Any]()
//        params[AdapterField.amount.rawValue] = amountModule.coinAmount.value
//        params[AdapterField.address.rawValue] = addressModule.address
////        params[AdapterField.feeRate.rawValue] = feeModule.feeRate
//
//        interactor.validate(params: params)
//        interactor.updateFee(params: params)
//    }
//
//    private func updateSendButtonState() {
////        let enabled = amountModule.validState && addressModule.validState && feeModule.validState
//
////        view?.set(sendButtonEnabled: enabled)
//    }
//
//}
//
//extension SendPresenter: ISendViewDelegate {
//
//    func showKeyboard() {
//        amountModule.showKeyboard()
//    }
//
//    func onViewDidLoad() {
//        view?.set(coin: interactor.coin)
//        updateModules()
//    }
//
//    func onClose() {
//        view?.dismissKeyboard()
//        router.dismiss()
//    }
//
//    func onCopyAddress() {
//        guard let address = addressModule.address else {
//            return
//        }
//
//        interactor.copy(address: address)
//        view?.showCopied()
//    }
//
//    func onSendClicked() {
//        do {
//            let item = try factory.confirmationItem(sendInputType: sendInputType, receiver: addressModule.address,
//                    showMemo: showMemo, coinAmountValue: amountModule.coinAmount, currencyAmountValue: amountModule.fiatAmount,
//                    coinFeeValue: feeModule.coinFee, currencyFeeValue: feeModule.fiatFee, estimateTime: nil)
//            router.showConfirmation(item: item, delegate: self)
//        } catch {
//            view?.show(error: error)
//        }
//    }
//
//}
//
//extension SendPresenter: ISendInteractorDelegate {
//
//    func didSend() {
//        view?.dismissWithSuccess()
//    }
//
//    func didFailToSend(error: Error) {
//        view?.show(error: error)
//    }
//
//    func onBecomeActive() {
//        // todo: Update rates when become active?
//    }
//
//    func didValidate(with errors: [SendStateError]) {
//        var amountValidationSuccess = true
//        errors.forEach {
//            switch($0) {
//            case .insufficientAmount(availableBalance: let availableBalance):
//                amountValidationSuccess = false
////                amountModule.insufficientAmount(availableBalance: availableBalance)
//            case .insufficientFeeBalance(fee: let fee):
//                feeModule.insufficientFeeBalance(coinCode: interactor.coin.code, fee: fee)
//            }
//        }
//        if amountValidationSuccess {
////            amountModule.onValidationSuccess()
//        }
//
//        updateSendButtonState()
//    }
//
//    func didUpdate(fee: Decimal) {
//        feeModule.update(fee: fee)
//    }
//
//}
//
//extension SendPresenter: ISendConfirmationDelegate {
//
//    func onSendClicked(memo: String?) {
//        guard let address = addressModule.address else {
//            view?.show(error: SendError.noAddress)
//            return
//        }
//        let amount = amountModule.coinAmount.value
//        guard amount != 0 else {
//            view?.show(error: SendError.noAmount)
//            return
//        }
//        var params = [String: Any]()
//        params[AdapterField.amount.rawValue] = amount
//        params[AdapterField.address.rawValue] = address
////        params[AdapterField.feeRate.rawValue] = feeModule.feeRate
//        params[AdapterField.memo.rawValue] = memo
//
//        interactor.send(params: params)
//    }
//
//}
//
//extension SendPresenter: ISendAmountDelegate {
//
//    var availableBalance: Decimal {
//        var params = [String: Any]()
//        params[AdapterField.address.rawValue] = addressModule.address
////        params[AdapterField.feeRate.rawValue] = feeModule.feeRate
//        do {
//            return try interactor.availableBalance(params: params)
//        } catch {
//            //
//        }
//        return 0
//    }
//
//    func onChangeAmount() {
//        updateModules()
//    }
//
//    func onChange(sendInputType: SendInputType) {
//        self.sendInputType = sendInputType
//
//        feeModule.update(sendInputType: sendInputType)
//    }
//
//}
//
//extension SendPresenter: ISendAddressDelegate {
//
//    func parse(paymentAddress: String) -> PaymentRequestAddress {
//        return interactor.parse(paymentAddress: paymentAddress)
//    }
//
//    func onAddressUpdate(address: String?) {
//        updateModules()
//    }
//
//    func onAmountUpdate(amount: Decimal) {
//        amountModule.set(amount: amount)
//    }
//
//    func scanQrCode(delegate: IScanQrCodeDelegate) {
//        router.scanQrCode(delegate: delegate)
//    }
//
//}
//
//extension SendPresenter: ISendFeeDelegate {
//
//    func updateFeeRate() {
//        updateModules()
//    }
//
//    func feeRate(priority: FeeRatePriority) -> Int {
//        return interactor.feeRate(priority: priority)
//    }
//
//}
