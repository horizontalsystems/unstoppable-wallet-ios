protocol ISendView: class {
    func set(coin: Coin)

    func set(amountInfo: AmountInfo?)
    func set(switchButtonEnabled: Bool)
    func set(hintInfo: HintInfo?)

    func set(addressInfo: AddressInfo?)

    func set(primaryFeeInfo: AmountInfo?)
    func set(secondaryFeeInfo: AmountInfo?)

    func set(sendButtonEnabled: Bool)

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
}

protocol ISendInteractor {
    var coin: Coin { get }
    var addressFromPasteboard: String? { get }
    func convertedAmount(forInputType inputType: SendInputType, amount: Double) -> Double?
    func state(forUserInput input: SendUserInput) -> SendState

    func send(userInput: SendUserInput)
}

protocol ISendInteractorDelegate: class {
    func didSend()
    func didFailToSend(error: Error)
}

protocol ISendRouter {
}

protocol ISendStateViewItemFactory {
    func viewItem(forState state: SendState) -> SendStateViewItem
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

struct SendStateViewItem {
    var amountInfo: AmountInfo?
    var switchButtonEnabled: Bool = false
    var hintInfo: HintInfo?
    var addressInfo: AddressInfo?
    var primaryFeeInfo: AmountInfo?
    var secondaryFeeInfo: AmountInfo?
    var sendButtonEnabled: Bool = false
}
