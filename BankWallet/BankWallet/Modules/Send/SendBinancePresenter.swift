//import Foundation
//
//class SendBinancePresenter {
//    weak var view: ISendView?
//
//    private let coin: Coin
//
//    private let interactor: ISendBinanceInteractor
//    private let router: ISendRouter
//    private let confirmationFactory: ISendConfirmationItemFactory
//
//    private let amountModule: ISendAmountModule
//    private let addressModule: ISendAddressModule
//    private let feeModule: ISendFeeModule
//
//    init(coin: Coin, interactor: ISendBinanceInteractor, router: ISendRouter, confirmationFactory: ISendConfirmationItemFactory, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule) {
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
//        view?.set(sendButtonEnabled: amountModule.validAmount != nil && addressModule.address != nil && feeModule.isValid)
//    }
//
//}
//
//extension SendBinancePresenter: ISendViewDelegate {
//
//    func showKeyboard() {
//        amountModule.showKeyboard()
//    }
//
//    func onViewDidLoad() {
//        view?.set(coin: coin)
//        amountModule.set(availableBalance: interactor.availableBalance)
//        feeModule.set(fee: interactor.fee)
//        feeModule.set(availableFeeBalance: interactor.availableBinanceBalance)
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
//extension SendBinancePresenter: ISendBinanceInteractorDelegate {
//
//    func didSend() {
//        view?.dismissWithSuccess()
//    }
//
//    func didFailToSend(error: Error) {
//        view?.show(error: error)
//    }
//
//}
//
//extension SendBinancePresenter: ISendConfirmationDelegate {
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
//        interactor.send(amount: amount, address: address, memo: memo)
//    }
//
//}
//
//extension SendBinancePresenter: ISendAmountDelegate {
//
//    func onChangeAmount() {
//        syncSendButton()
//    }
//
//    func onChange(inputType: SendInputType) {
//        feeModule.update(inputType: inputType)
//    }
//
//}
//
//extension SendBinancePresenter: ISendAddressDelegate {
//
//    func validate(address: String) throws {
//        try interactor.validate(address: address)
//    }
//
//    func onUpdateAddress() {
//        syncSendButton()
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
//extension SendBinancePresenter: ISendFeeDelegate {
//
//    var inputType: SendInputType {
//        return amountModule.inputType
//    }
//
//}
