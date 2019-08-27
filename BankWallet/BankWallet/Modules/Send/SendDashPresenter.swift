//import Foundation
//
//class SendDashPresenter {
//    weak var view: ISendView?
//
//    private let coin: Coin
//
//    private let interactor: ISendDashInteractor
//    private let router: ISendRouter
//    private let confirmationFactory: ISendConfirmationItemFactory
//
//    private let amountModule: ISendAmountModule
//    private let addressModule: ISendAddressModule
//    private let feeModule: ISendFeeModule
//
//    init(coin: Coin, interactor: ISendDashInteractor, router: ISendRouter, confirmationFactory: ISendConfirmationItemFactory, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule) {
//        self.coin = coin
//
//        self.interactor = interactor
//        self.router = router
//        self.confirmationFactory = confirmationFactory
//
//        self.amountModule = amountModule
//        self.addressModule = addressModule
//        self.feeModule = feeModule
//    }
//
//    private func syncSendButton() {
//        view?.set(sendButtonEnabled: amountModule.validAmount != nil && addressModule.address != nil)
//    }
//
//    private func syncAvailableBalance() {
//        interactor.fetchAvailableBalance(address: addressModule.address)
//    }
//
//    private func syncFee() {
//        interactor.fetchFee(amount: amountModule.coinAmount.value, address: addressModule.address)
//    }
//
//}
//
//extension SendDashPresenter: ISendViewDelegate {
//
//    func showKeyboard() {
//        amountModule.showKeyboard()
//    }
//
//    func onViewDidLoad() {
//        view?.set(coin: coin)
//        syncAvailableBalance()
//    }
//
//    func onClose() {
//        view?.dismissKeyboard()
//        router.dismiss()
//    }
//
//    func onProceedClicked() {
//        guard let address = addressModule.address else {
//            return
//        }
//
//        guard let item = confirmationFactory.viewItem(sendInputType: amountModule.inputType, coinAmountValue: amountModule.coinAmount,
//                currencyAmountValue: amountModule.fiatAmount, receiver: address, showMemo: false, coinFeeValue: feeModule.coinValue,
//                currencyFeeValue: feeModule.currencyValue, estimateTime: nil) else {
//            return
//        }
//
//        router.showConfirmation(item: item, delegate: self)
//    }
//
//}
//
//extension SendDashPresenter: ISendDashInteractorDelegate {
//
//    func didSend() {
//        view?.dismissWithSuccess()
//    }
//
//    func didFailToSend(error: Error) {
//        view?.show(error: error)
//    }
//
//    func didFetch(availableBalance: Decimal) {
//        amountModule.set(availableBalance: availableBalance)
//        syncSendButton()
//    }
//
//    func didFetch(fee: Decimal) {
//        feeModule.set(fee: fee)
//    }
//
//}
//
//extension SendDashPresenter: ISendConfirmationDelegate {
//
//    func onSendClicked(memo: String?) {
//        guard let address = addressModule.address else {
//            return
//        }
//
//        guard let amount = amountModule.validAmount else {
//            return
//        }
//
//        view?.showProgress()
//        interactor.send(amount: amount, address: address)
//    }
//
//}
//
//extension SendDashPresenter: ISendAmountDelegate {
//
//    func onChangeAmount() {
//        syncFee()
//        syncSendButton()
//    }
//
//    func onChange(inputType: SendInputType) {
//        feeModule.update(inputType: inputType)
//    }
//
//}
//
//extension SendDashPresenter: ISendAddressDelegate {
//
//    func validate(address: String) throws {
//        try interactor.validate(address: address)
//    }
//
//    func onUpdateAddress() {
//        syncAvailableBalance()
//        syncFee()
//    }
//
//    func onUpdate(amount: Decimal) {
//        amountModule.set(amount: amount)
//    }
//
//    func scanQrCode(delegate: IScanQrCodeDelegate) {
//        router.scanQrCode(delegate: delegate)
//    }
//
//}
//
//extension SendDashPresenter: ISendFeeDelegate {
//
//    var inputType: SendInputType {
//        return amountModule.inputType
//    }
//
//}
