import UIKit
import CurrencyKit

protocol ISendAmountView: AnyObject {
    func set(loading: Bool)
    func set(prefix: String?)
    func set(availableAmount: AmountInfo?)
    func set(amount: AmountInfo?)
    func setAmountColor(inputType: SendInputType)
    func set(hint: AmountInfo?)
    func setHintColor(inputType: SendInputType)
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

    var sendAmountInfo: SendAmountInfo { get }
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

protocol ISendAmountDelegate: AnyObject {
    func onChangeAmount()
    func onChange(inputType: SendInputType)
}

protocol IAmountDecimalParser {
    func parseAnyDecimal(from string: String?) -> Decimal?
}

enum SendAmountInfo {
    case max
    case entered(amount: Decimal)
    case notEntered
}
