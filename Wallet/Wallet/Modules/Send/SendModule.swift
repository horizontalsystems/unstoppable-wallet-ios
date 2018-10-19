import UIKit

protocol ISendView: class {
    func setTitle(_ title: String?)
    func setAddress(_ address: String?)
    func setCurrency(code: String)
    func setAmount(amount: String?)
    func setAmountHint(hint: String, color: UIColor, error: SendError?)
    func closeView()
    func showError(error: String)
    func showSuccess()
    func showKeyboard()
    func showAddressWarning(_ valid: Bool)
}

protocol ISendViewDelegate {
    func onScanClick()
    func onPasteClick()
    func onCurrencyButtonClick()
    func onViewDidLoad()
    func onViewDidAppear()
    func onAmountEntered(amount: String?)
    func onAddressEntered(address: String?)
    func onCancelClick()
    func onSendClick(address: String?)
}

protocol ISendInteractor {
    func getCoin() -> Coin
    func getBaseCurrency() -> String
    func getCopiedText() -> String?
    func fetchExchangeRate()
    func send(address: String, amount: Double)
    func isValid(address: String?) -> Bool
}

protocol ISendInteractorDelegate: class {
    func didFetchExchangeRate(exchangeRate: Double)
    func didFailToSend(error: Error)
    func didSend()
}

protocol ISendRouter {
    func startScan(result: (@escaping (String) -> ()))
}
