import Foundation
import WalletKit
import RealmSwift

class SendPresenter {

    var interactor: ISendInteractor
    let router: ISendRouter
    weak var view: ISendView?

    var baseCurrencyCode: String
    private var isEnteringInCrypto = false
    var exchangeRate: Double = 0
    private var enteredAmount: Double?

    private var fiatAmount: Double?
    private var cryptoAmount: Double?

    var coinCode: String

    init(interactor: ISendInteractor, router: ISendRouter, coinCode: String) {
        self.coinCode = coinCode
        self.interactor = interactor
        self.router = router
        baseCurrencyCode = interactor.getBaseCurrency()
    }

}

extension SendPresenter: ISendInteractorDelegate {

    func didFetchExchangeRate(exchangeRate: Double) {
        self.exchangeRate = exchangeRate
        refreshAmountHint()
    }

    func didFailToSend(error: Error) {
        view?.showError(error: getError(error))
    }

    func didSend() {
        view?.showSuccess()
    }

    private func getError(_ error: Error) -> String {
        return (error as? SendError)?.localizedDescription ?? "some error"
    }

}

extension SendPresenter: ISendViewDelegate {

    func onScanClick() {
        router.startScan()
    }

    func onPasteClick() {
        let copiedText = interactor.getCopiedText()
        view?.setAddress(copiedText)
    }

    func onCurrencyButtonClick() {
        isEnteringInCrypto = !isEnteringInCrypto

        refreshAmountHint()
        updateAmounts()
    }

    func onViewDidLoad() {
        updateAmounts()

        interactor.fetchExchangeRate()
    }

    func onViewDidAppear() {
        view?.showKeyboard()
    }

    func onAmountEntered(amount: String?) {
        enteredAmount = Double(amount ?? "0")
        refreshAmountHint()
    }

    func onCancelClick() {
        print("onCancelClick")
    }

    func onSendClick(address: String?) {
        if let cryptoAmount = cryptoAmount, let address = address {
            interactor.send(coinCode: coinCode, address: address, amount: cryptoAmount)
        }
    }

    private func updateAmounts() {
        updateAmountView()
//        updateAmountHintView(error: nil)
    }

    private func updateAmountView() {
        let amount = (isEnteringInCrypto ? cryptoAmount : fiatAmount) ?? 0
        let amountStr = isEnteringInCrypto ? CurrencyHelper.instance.formatCryptoAmount(amount) : CurrencyHelper.instance.formatFiatAmount(amount)
        let currency = isEnteringInCrypto ? coinCode : baseCurrencyCode

        view?.setCurrency(code: currency)
        view?.setAmount(amount: amount > 0.0 ? amountStr : nil)
    }

    private func updateAmountHintView(error: SendError?) {
        let amount = (isEnteringInCrypto ? fiatAmount : cryptoAmount) ?? 0
        let amountStr = isEnteringInCrypto ? CurrencyHelper.instance.formatFiatAmount(amount) : CurrencyHelper.instance.formatCryptoAmount(amount)
        let currency = isEnteringInCrypto ? baseCurrencyCode : coinCode

        view?.setAmountHint(hint: "\(amountStr) \(currency)", error: error)
    }

    private func refreshAmountHint() {
        if isEnteringInCrypto {
            cryptoAmount = enteredAmount
            fiatAmount = (enteredAmount ?? 0) * exchangeRate
        } else {
            fiatAmount = enteredAmount
            cryptoAmount = (enteredAmount ?? 0) / exchangeRate
        }

        updateAmountHintView(error: (cryptoAmount ?? 0 > Double(33)) ? SendError.insufficientFunds : nil)
    }

}
