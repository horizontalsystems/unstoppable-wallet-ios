import UIKit

protocol ISendAmountView: class {
    func set(amountType: String)
    func set(amount: AmountInfo?)
    func set(hint: AmountInfo?)
    func set(error: Error?)

    func set(switchButtonEnabled: Bool)
    func set(maxButtonVisible: Bool)

    func showKeyboard()
}

protocol ISendAmountViewDelegate {
    func viewDidLoad()

    func isValid(text: String) -> Bool
    func onChanged(amountText: String?)

    func onSwitchClicked()
    func onMaxClicked()
}

protocol ISendAmountInteractor {
    var defaultInputType: SendInputType { get }
    func set(inputType: SendInputType)

    var baseCurrency: Currency { get }
    func rate(coinCode: CoinCode, currencyCode: String) -> Rate?
}

protocol ISendAmountModule: AnyObject {
    var delegate: ISendAmountDelegate? { get set }

    var currentAmount: Decimal { get }
    func validAmount() throws -> Decimal

    var inputType: SendInputType { get }

    func primaryAmountInfo() throws -> AmountInfo
    func secondaryAmountInfo() throws -> AmountInfo?

    func showKeyboard()

    func set(amount: Decimal)
    func set(availableBalance: Decimal)
}

protocol ISendAmountDelegate: class {
    func onChangeAmount()
    func onChange(inputType: SendInputType)
}

protocol ISendAmountDecimalParser {
    func parseAnyDecimal(from string: String?) -> Decimal?
}
