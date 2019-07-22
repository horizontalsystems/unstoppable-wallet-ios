import Foundation

protocol ISendView: class {
    func set(coin: Coin)

    func showConfirmation(viewItem: SendConfirmationViewItem)
    func showCopied()
    func show(error: Error)
    func showProgress()
    func dismissWithSuccess()
}

protocol ISendViewDelegate {
    func showKeyboard()

    var isFeeAdjustable: Bool { get }

    var sendItems: [SendItem] { get }

    func onViewDidLoad()
    func onClose()

    func onAmountChanged(amount: Decimal)
    func onSwitchClicked()

    func onConfirmClicked()

    func onCopyAddress()
    func onMaxClicked()

    func onPasteAmountClicked()
    func onFeePriorityChange(value: Int)
}

protocol ISendInteractor {
    var defaultInputType: SendInputType { get }
    var coin: Coin { get }
    var valueFromPasteboard: String? { get }
    func parse(paymentAddress: String) -> PaymentRequestAddress
    func convertedAmount(forInputType inputType: SendInputType, amount: Decimal) -> Decimal?
    func state(forUserInput input: SendUserInput) -> SendState
    func totalBalanceMinusFee(forInputType input: SendInputType, address: String?, feeRatePriority: FeeRatePriority) -> Decimal
    func copy(address: String)
    func send(userInput: SendUserInput)

    func set(inputType: SendInputType)
    func retrieveRate()
}

protocol ISendInteractorDelegate: class {
    func didRetrieve(rate: Rate?)
    func didRetrieveFeeRate()
    func didSend()
    func didFailToSend(error: Error)
    func onBecomeActive()
}

protocol ISendRouter {
    func scanQrCode(onCodeParse: ((String) -> ())?)
    func dismiss()
}

protocol ISendStateViewItemFactory {
    func viewItem(forState state: SendState, forceRoundDown: Bool) -> SendStateViewItem
    func confirmationViewItem(forState state: SendState, coin: Coin) -> SendConfirmationViewItem?
}

protocol ISendAmountDelegate: class {
    func onSwitchClicked()
    func onChanged(amount: Decimal)
    func onMaxClicked()

    func onPasteClicked()
}

protocol ISendAmountListener: class {
    func showKeyboard()
}

protocol ISendAddressDelegate: class {
    func onAddressScanClicked()
    func onAddressPasteClicked()
    func onAddressDeleteClicked()
}

protocol ISendButtonDelegate: class {
    func onSendClicked()
}

protocol ISendFeeDelegate: class {
    func onFeePriorityChange(value: Int)
}

enum SendInputType: String {
    case coin = "coin"
    case currency = "currency"
}

enum SendStateError {
    case insufficientAmount
    case insufficientFeeBalance
}

enum AddressError: Error {
    case invalidAddress
}

enum HintInfo {
    case amount(amountInfo: AmountInfo)
    case error(error: AmountInfo)
}

struct FeeInfo {
    var primaryFeeInfo: AmountInfo?
    var secondaryFeeInfo: AmountInfo?
    var error: FeeError?
}

enum AddressInfo {
    case address(address: String)
    case invalidAddress(address: String, error: AddressError)
}

enum AmountInfo {
    case coinValue(coinValue: CoinValue)
    case currencyValue(currencyValue: CurrencyValue)
}

enum FeeError {
    case erc20error(erc20CoinCode: String, fee: CoinValue)
}

class SendInteractorState {
    let adapter: IAdapter
    var exchangeRate: Rate?
    var feeExchangeRate: Rate?

    init(adapter: IAdapter) {
        self.adapter = adapter
    }
}

class SendUserInput {
    var inputType: SendInputType = .coin
    var amount: Decimal = 0
    var address: String?
    var feeRatePriority: FeeRatePriority = .medium
}

class SendState {
    var decimal: Int
    var inputType: SendInputType
    var coinValue: CoinValue?
    var currencyValue: CurrencyValue?
    var amountError: AmountInfo?
    var feeError: FeeError?
    var address: String?
    var addressError: AddressError?
    var feeCoinValue: CoinValue?
    var feeCurrencyValue: CurrencyValue?

    init(decimal: Int, inputType: SendInputType) {
        self.decimal = decimal
        self.inputType = inputType
    }
}

class SendStateViewItem {
    var decimal: Int
    var amountInfo: AmountInfo?
    var switchButtonEnabled: Bool = false
    var hintInfo: HintInfo?
    var addressInfo: AddressInfo?
    var feeInfo: FeeInfo?
    var sendButtonEnabled: Bool = false

    init(decimal: Int) {
        self.decimal = decimal
    }

}

class SendConfirmationViewItem {
    let coin: Coin
    let primaryAmountInfo: AmountInfo
    var secondaryAmountInfo: AmountInfo?
    let address: String
    let feeInfo: AmountInfo
    let totalInfo: AmountInfo?

    init(coin: Coin, primaryAmountInfo: AmountInfo, address: String, feeInfo: AmountInfo, totalInfo: AmountInfo?) {
        self.coin = coin
        self.primaryAmountInfo = primaryAmountInfo
        self.address = address
        self.feeInfo = feeInfo
        self.totalInfo = totalInfo
    }
}
