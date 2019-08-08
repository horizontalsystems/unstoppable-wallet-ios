//import Foundation
//
//class EOSSendPresenter {
//    weak var view: ISendView?
//
//    private let interactor: ISendInteractor
//    private let router: ISendRouter
//    private let factory: ISendConfirmationItemFactory
//
//    private let amountModule: ISendAmountModule
//    private let addressModule: ISendAddressModule
//
//    private var sendInputType: SendInputType = .coin
//
//    init(interactor: ISendInteractor, router: ISendRouter, factory: ISendConfirmationItemFactory, amountModule: ISendAmountModule, addressModule: ISendAddressModule) {
//        self.interactor = interactor
//        self.router = router
//        self.factory = factory
//
//        self.amountModule = amountModule
//        self.addressModule = addressModule
//    }
//
//    private func updateModules() {
//        var params = [String: Any]()
//        params[AdapterField.amount.rawValue] = amountModule.coinAmount.value
//        params[AdapterField.address.rawValue] = addressModule.address
//
//        interactor.validate(params: params)
//    }
//
//    private func updateSendButtonState() {
////        let enabled = amountModule.validState && addressModule.validState
//
////        view?.set(sendButtonEnabled: enabled)
//    }
//
//}
//
//extension EOSSendPresenter: ISendViewDelegate {
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
//                    showMemo: true, coinAmountValue: amountModule.coinAmount, currencyAmountValue: amountModule.fiatAmount,
//                    coinFeeValue: nil, currencyFeeValue: nil, estimateTime: nil)
//            router.showConfirmation(item: item, delegate: self)
//        } catch {
//            view?.show(error: error)
//        }
//    }
//
//}
//
//extension EOSSendPresenter: ISendInteractorDelegate {
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
//            default: ()
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
//        //
//    }
//
//}
//
//extension EOSSendPresenter: ISendConfirmationDelegate {
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
//        params[AdapterField.memo.rawValue] = memo
//
//        interactor.send(params: params)
//    }
//
//}
//
//extension EOSSendPresenter: ISendAmountDelegate {
//
//    var availableBalance: Decimal {
//        var params = [String: Any]()
//        params[AdapterField.address.rawValue] = addressModule.address
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
//    }
//
//}
//
//extension EOSSendPresenter: ISendAddressDelegate {
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
//        // todo:
//    }
//
//    func scanQrCode(delegate: IScanQrCodeDelegate) {
//        router.scanQrCode(delegate: delegate)
//    }
//
//}
