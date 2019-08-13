import Foundation

protocol ISendView: class {
    func set(coin: Coin)

    func showCopied()
    func show(error: Error)
    func showProgress()
    func set(sendButtonEnabled: Bool)
    func dismissKeyboard()
    func dismissWithSuccess()
}

protocol ISendViewDelegate {
    func showKeyboard()

    func onViewDidLoad()
    func onClose()

    func onSendClicked()
}

protocol ISendBitcoinInteractor {
    var coin: Coin { get }
    func fetchAvailableBalance(feeRate: Int, address: String?)
    func validate(address: String) throws
    func fetchFee(amount: Decimal, feeRate: Int, address: String?)
    func send(amount: Decimal, address: String, feeRate: Int)
}

protocol ISendBitcoinInteractorDelegate: class {
    func didFetch(availableBalance: Decimal)
    func didFetch(fee: Decimal)
    func didSend()
    func didFailToSend(error: Error)
}

protocol ISendEthereumInteractor {
    var coin: Coin { get }
    func availableBalance(gasPrice: Int) -> Decimal
    func validate(address: String) throws
    func fee(gasPrice: Int) -> Decimal
    func send(amount: Decimal, address: String, gasPrice: Int)
}

protocol ISendEthereumInteractorDelegate: class {
    func didSend()
    func didFailToSend(error: Error)
}

protocol ISendErc20Interactor {
    var coin: Coin { get }
    var availableBalance: Decimal { get }
    var availableEthereumBalance: Decimal { get }
    func validate(address: String) throws
    func fee(gasPrice: Int) -> Decimal
    func send(amount: Decimal, address: String, gasPrice: Int)
}

protocol ISendErc20InteractorDelegate: class {
    func didSend()
    func didFailToSend(error: Error)
}

protocol ISendEosInteractor {
    var coin: Coin { get }
    var availableBalance: Decimal { get }
    func validate(account: String) throws
    func send(amount: Decimal, account: String, memo: String?)
}

protocol ISendEosInteractorDelegate: class {
    func didSend()
    func didFailToSend(error: Error)
}

protocol ISendBinanceInteractor {
    var coin: Coin { get }
    var availableBalance: Decimal { get }
    var availableBinanceBalance: Decimal { get }
    func validate(address: String) throws
    var fee: Decimal { get }
    func send(amount: Decimal, address: String, memo: String?)
}

protocol ISendBinanceInteractorDelegate: class {
    func didSend()
    func didFailToSend(error: Error)
}

protocol ISendRouter {
    func showConfirmation(item: SendConfirmationViewItem, delegate: ISendConfirmationDelegate)
    func scanQrCode(delegate: IScanQrCodeDelegate)
    func dismiss()
}

protocol ISendConfirmationItemFactory {
    func viewItem(sendInputType: SendInputType, coinAmountValue: CoinValue, currencyAmountValue: CurrencyValue?, receiver: String, showMemo: Bool, coinFeeValue: CoinValue?, currencyFeeValue: CurrencyValue?, estimateTime: String?) -> SendConfirmationViewItem?
}

enum SendInputType: String {
    case coin = "coin"
    case currency = "currency"

    var reversed: SendInputType { return self == .coin ? .currency : .coin }
}

enum AmountInfo {
    case coinValue(coinValue: CoinValue)
    case currencyValue(currencyValue: CurrencyValue)

    var formattedString: String? {
        switch self {
        case .coinValue(let coinValue):
            return ValueFormatter.instance.formatNew(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            return ValueFormatter.instance.formatNew(currencyValue: currencyValue)
        }
    }

}

class SendConfirmationViewItem {
    let primaryAmount: String
    var secondaryAmount: String?
    let receiver: String
    let showMemo: Bool
    let feeInfo: String?
    let totalInfo: String?
    let estimateTime: String?

    init(primaryAmount: String, secondaryAmount: String?, receiver: String, showMemo: Bool, feeInfo: String?, totalInfo: String?, estimateTime: String?) {
        self.primaryAmount = primaryAmount
        self.secondaryAmount = secondaryAmount
        self.receiver = receiver
        self.showMemo = showMemo
        self.feeInfo = feeInfo
        self.totalInfo = totalInfo
        self.estimateTime = estimateTime
    }

}
