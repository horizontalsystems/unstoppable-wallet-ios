import Foundation

protocol ISendView: class {
    func set(coin: Coin)

    func showCopied()
    func show(error: Error)
    func showProgress()
    func showConfirmation(viewItem: SendConfirmationViewItem)
    func set(sendButtonEnabled: Bool)
    func dismissKeyboard()
    func dismissWithSuccess()

    func addAmountModule(coinCode: CoinCode, decimal: Int, delegate: ISendAmountDelegate) -> ISendAmountModule
    func addAddressModule(delegate: ISendAddressPresenterDelegate) -> ISendAddressModule
    func addFeeModule(coinCode: CoinCode, decimal: Int, delegate: ISendFeePresenterDelegate) -> ISendFeeModule
    func addSendButton()
}

protocol ISendViewDelegate {
    func showKeyboard()

    func onViewDidLoad()
    func onClose()

    func onCopyAddress()

    func onSendClicked()
    func onConfirmClicked()
}

protocol ISendInteractor {
    var coin: Coin { get }
    func availableBalance(params: [String: Any]) throws -> Decimal

    func copy(address: String)
    func parse(paymentAddress: String) -> PaymentRequestAddress

    func send(amount: Decimal, address: String, feeRatePriority: FeeRatePriority)
    func validate(params: [String: Any])
    func updateFee(params: [String: Any])
}

protocol ISendInteractorDelegate: class {
    func didSend()
    func didFailToSend(error: Error)
    func onBecomeActive()

    func didValidate(with errors: [SendStateError])
    func didUpdate(fee: Decimal)
}

protocol ISendRouter {
    func scanQrCode(onCodeParse: ((String) -> ())?)
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
    func errorValue(fee: Decimal, coinCode: CoinCode) -> String
}

protocol ISendConfirmationViewItemFactory {
    func confirmationViewItem(coin: Coin, sendInputType: SendInputType, address: String?, coinAmountValue: CoinValue, currencyAmountValue: CurrencyValue?, coinFeeValue: CoinValue, currencyFeeValue: CurrencyValue?) throws -> SendConfirmationViewItem
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
    let coin: Coin
    let primaryAmountInfo: AmountInfo
    var secondaryAmountInfo: AmountInfo?
    let address: String
    let feeInfo: AmountInfo
    let totalInfo: AmountInfo?

    init(coin: Coin, primaryAmountInfo: AmountInfo, secondaryAmountInfo: AmountInfo?, address: String, feeInfo: AmountInfo, totalInfo: AmountInfo?) {
        self.coin = coin
        self.primaryAmountInfo = primaryAmountInfo
        self.secondaryAmountInfo = secondaryAmountInfo
        self.address = address
        self.feeInfo = feeInfo
        self.totalInfo = totalInfo
    }
}
