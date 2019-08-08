import UIKit

protocol ISendAmountView: class {
    func set(type: String?, amount: String?)
    func set(hint: String?)
    func set(error: String?)
    func set(switchButtonEnabled: Bool)

    func maxButton(show: Bool)
    func showKeyboard()
}

protocol ISendAmountViewDelegate {
    func viewDidLoad()

    func validateInputText(text: String) -> Bool

    func onSwitchClicked()
    func onChanged(amountText: String?)
    func onMaxClicked()
}

protocol ISendAmountInteractor {
    var defaultInputType: SendInputType { get }

    func set(inputType: SendInputType)

    func rate(coinCode: CoinCode, currencyCode: String) -> Rate?
    func decimal(coinDecimal: Int, inputType: SendInputType) -> Int
}

protocol ISendAmountModule: AnyObject {
    var delegate: ISendAmountDelegate? { get set }

    var validAmount: Decimal? { get }

    var sendInputType: SendInputType { get }
    var coinAmount: CoinValue { get }
    var fiatAmount: CurrencyValue? { get }

    func showKeyboard()

    func set(amount: Decimal)
    func set(availableBalance: Decimal)
}

protocol ISendAmountDelegate: class {
    func onChangeAmount()
    func onChange(sendInputType: SendInputType)
}
