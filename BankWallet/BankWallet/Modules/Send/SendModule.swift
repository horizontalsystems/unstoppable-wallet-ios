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

    func onCopyAddress()

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

protocol ISendRouter {
    func showConfirmation(item: SendConfirmationViewItem, delegate: ISendConfirmationDelegate)
    func scanQrCode(delegate: IScanQrCodeDelegate)
    func dismiss()
}

protocol ISendAmountFormatHelper {
    func prefix(inputType: SendInputType, rate: Rate?) -> String?
    func coinAmount(amountText: String, inputType: SendInputType, rate: Rate?) -> Decimal?
    func convert(value: Decimal, currency: Currency, rate: Rate?) -> CurrencyValue?
    func formatted(value: Decimal, inputType: SendInputType, rate: Rate?) -> String?
    func formattedWithCode(value: Decimal, inputType: SendInputType, rate: Rate?) -> String?

    func errorValue(availableBalance: Decimal, inputType: SendInputType, rate: Rate?) -> String?
}

protocol ISendFeeFormatHelper {
    func convert(value: Decimal, currency: Currency, rate: Rate?) -> CurrencyValue?
    func formattedWithCode(value: Decimal, inputType: SendInputType, rate: Rate?) -> String?
    func errorValue(feeValue: CoinValue, coinProtocol: String, baseCoinName: String, coinCode: CoinCode) -> String
}

protocol ISendConfirmationItemFactory {
    func confirmationItem(sendInputType: SendInputType, receiver: String?, showMemo: Bool, coinAmountValue: CoinValue, currencyAmountValue: CurrencyValue?, coinFeeValue: CoinValue?, currencyFeeValue: CurrencyValue?, estimateTime: String?) throws -> SendConfirmationViewItem
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
