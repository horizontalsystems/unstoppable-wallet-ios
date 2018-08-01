import Foundation
import WalletKit

protocol ISendView: class {
    func setAddress(_ address: String?)
    func setCurrency(code: String)
    func setAmount(amount: String?)
    func setAmountHint(hint: String, error: SendError?)
    func closeView()
    func showError(error: String)
    func showSuccess()
}

protocol ISendViewDelegate {
    func onScanClick()
    func onPasteClick()
    func onCurrencyButtonClick()
    func onViewDidLoad()
    func onAmountEntered(amount: String?)
    func onCancelClick()
    func onSendClick(address: String?)
}

protocol ISendInteractor {
    func getBaseCurrency() -> String
    func getCopiedText() -> String?
    func fetchExchangeRate()
    func send(coinCode: String, address: String, amount: Double)
}

protocol ISendInteractorDelegate: class {
    func didFetchExchangeRate(exchangeRate: Double)
    func didFailToSend(error: Error)
    func didSend()
}

protocol ISendRouter {
    func startScan()
}
