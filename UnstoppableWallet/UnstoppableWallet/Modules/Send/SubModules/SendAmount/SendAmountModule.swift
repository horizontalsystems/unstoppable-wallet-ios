import UIKit
import CurrencyKit

protocol ISendAmountView: class {
    func set(loading: Bool)
    func set(amountType: String)
    func set(availableBalance: AmountInfo?)
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

    func willChangeAmount(text: String?)
    func didChangeAmount()

    func onSwitchClicked()
    func onMaxClicked()
}

protocol ISendAmountInteractor {
    func set(inputType: SendInputType)

    var baseCurrency: Currency { get }
}

protocol ISendAmountModule: AnyObject {
    var delegate: ISendAmountDelegate? { get set }

    var currentAmount: Decimal { get }
    func validAmount() throws -> Decimal

    func primaryAmountInfo() throws -> AmountInfo
    func secondaryAmountInfo() throws -> AmountInfo?

    func showKeyboard()

    func set(loading: Bool)
    func set(amount: Decimal)
    func set(rateValue: Decimal?)
    func set(inputType: SendInputType)
    func set(availableBalance: Decimal)
    func set(maximumAmount: Decimal?)
    func set(minimumAmount: Decimal)
    func set(minimumRequiredBalance: Decimal)
}

protocol ISendAmountDelegate: class {
    func onChangeAmount()
    func onChange(inputType: SendInputType)
}

protocol ISendAmountDecimalParser {
    func parseAnyDecimal(from string: String?) -> Decimal?
}
