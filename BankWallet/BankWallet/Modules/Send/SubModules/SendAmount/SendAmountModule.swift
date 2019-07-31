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

protocol ISendAmountDelegate: class {
    var availableBalance: Decimal { get }
    func onChanged()
    func onChanged(sendInputType: SendInputType)
}

protocol ISendAmountInteractor {
    var defaultInputType: SendInputType { get }

    func set(inputType: SendInputType)

    func rate(coinCode: CoinCode, currencyCode: String) -> Rate?
    func decimal(coinDecimal: Int, inputType: SendInputType) -> Int
}

protocol ISendAmountModule {
    var coinAmount: CoinValue { get }
    var fiatAmount: CurrencyValue? { get }

    var validState: Bool { get }

    func showKeyboard()

    func insufficientAmount(availableBalance: Decimal)
    func onValidationSuccess()
}
