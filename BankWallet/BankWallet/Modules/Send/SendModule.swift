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

protocol ISendInteractor {
    var coin: Coin { get }
    var decimal: Int { get }
    func availableBalance(params: [String: Any]) throws -> Decimal

    func copy(address: String)
    func parse(paymentAddress: String) -> PaymentRequestAddress

    func send(params: [String: Any])
    func validate(params: [String: Any])
    func updateFee(params: [String: Any])
    func feeRate(priority: FeeRatePriority) -> Int
}

protocol ISendInteractorDelegate: class {
    func didSend()
    func didFailToSend(error: Error)
    func onBecomeActive()

    func didValidate(with errors: [SendStateError])
    func didUpdate(fee: Decimal)
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

enum SendStateError {
    case insufficientAmount(availableBalance: Decimal)
    case insufficientFeeBalance(fee: Decimal)
}

extension SendStateError: Equatable {

    public static func ==(lhs: SendStateError, rhs: SendStateError) -> Bool {
        switch (lhs, rhs) {
        case (let .insufficientAmount(lhsBalance), let .insufficientAmount(rhsBalance)): return lhsBalance == rhsBalance
        case (let .insufficientFeeBalance(lhsFee), let .insufficientFeeBalance(rhsFee)): return lhsFee == rhsFee
        default: return false
        }
    }

}

enum AddressError: Error {
    case invalidAddress
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

enum FeeError {
    case erc20error(erc20CoinCode: String, fee: CoinValue)
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
