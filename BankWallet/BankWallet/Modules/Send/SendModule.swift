protocol ISendView: class {
    func set(coinCode: CoinCode)

    func set(amountInfo: AmountInfo?)
    func set(switchButtonEnabled: Bool)
    func set(hintInfo: HintInfo?)

    func set(addressInfo: AddressInfo?)

    func set(primaryFeeInfo: AmountInfo?)
    func set(secondaryFeeInfo: AmountInfo?)

    func set(sendButtonEnabled: Bool)

    func showConfirmation(viewItem: SendConfirmationViewItem)
    func showCopied()
    func show(error: Error)
    func dismissWithSuccess()
}

protocol ISendViewDelegate {
    func onViewDidLoad()

    func onAmountChanged(amount: Double)
    func onSwitchClicked()

    func onPasteClicked()
    func onScan(address: String)
    func onDeleteClicked()

    func onSendClicked()
    func onConfirmClicked()

    func onCopyAddress()
}

protocol ISendInteractor {
    var coinCode: CoinCode { get }
    var addressFromPasteboard: String? { get }
    func parse(paymentAddress: String) -> PaymentRequestAddress
    func convertedAmount(forInputType inputType: SendInputType, amount: Double) -> Double?
    func state(forUserInput input: SendUserInput) -> SendState

    func copy(address: String)
    func send(userInput: SendUserInput)

    func fetchRate()
}

protocol ISendInteractorDelegate: class {
    func didUpdateRate()
    func didSend()
    func didFailToSend(error: Error)
}

protocol ISendRouter {
}

protocol ISendStateViewItemFactory {
    func viewItem(forState state: SendState) -> SendStateViewItem
    func confirmationViewItem(forState state: SendState) -> SendConfirmationViewItem?
}

enum SendInputType {
    case coin
    case currency
}

enum AmountError: Error {
    case insufficientAmount(amountInfo: AmountInfo)
}

enum AddressError: Error {
    case invalidAddress
}

enum HintInfo {
    case amount(amountInfo: AmountInfo)
    case error(error: AmountError)
}

enum AddressInfo {
    case address(address: String)
    case invalidAddress(address: String, error: AddressError)
}

enum AmountInfo {
    case coinValue(coinValue: CoinValue)
    case currencyValue(currencyValue: CurrencyValue)
}

class SendUserInput {
    var inputType: SendInputType = .coin
    var amount: Double = 0
    var address: String?
}

class SendState {
    var inputType: SendInputType
    var coinValue: CoinValue?
    var currencyValue: CurrencyValue?
    var amountError: AmountError?
    var address: String?
    var addressError: AddressError?
    var feeCoinValue: CoinValue?
    var feeCurrencyValue: CurrencyValue?

    init(inputType: SendInputType) {
        self.inputType = inputType
    }
}

class SendStateViewItem {
    var amountInfo: AmountInfo?
    var switchButtonEnabled: Bool = false
    var hintInfo: HintInfo?
    var addressInfo: AddressInfo?
    var primaryFeeInfo: AmountInfo?
    var secondaryFeeInfo: AmountInfo?
    var sendButtonEnabled: Bool = false
}

class SendConfirmationViewItem {
    let coinValue: CoinValue
    var currencyValue: CurrencyValue?
    let address: String
    let feeInfo: AmountInfo
    let totalInfo: AmountInfo

    init(coinValue: CoinValue, address: String, feeInfo: AmountInfo, totalInfo: AmountInfo) {
        self.coinValue = coinValue
        self.address = address
        self.feeInfo = feeInfo
        self.totalInfo = totalInfo
    }
}
