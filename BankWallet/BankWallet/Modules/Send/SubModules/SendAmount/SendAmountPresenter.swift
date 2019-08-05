import Foundation

class SendAmountPresenter {
    private let interactor: ISendAmountInteractor
    private let formatHelper: ISendAmountFormatHelper
    private let currencyManager: ICurrencyManager

    private let coinCode: CoinCode
    private let coinDecimal: Int

    weak var view: ISendAmountView?
    weak var delegate: ISendAmountDelegate?

    private var sendInputType: SendInputType = .coin

    private var amount: Decimal?
    private var switchButtonEnabled: Bool = false
    private var rate: Rate?
    private var insufficientAmountWithAvailableBalance: Decimal?

    init(interactor: ISendAmountInteractor, formatHelper: ISendAmountFormatHelper, currencyManager: ICurrencyManager, coinCode: CoinCode, coinDecimal: Int) {
        self.interactor = interactor
        self.formatHelper = formatHelper
        self.currencyManager = currencyManager

        self.coinCode = coinCode
        self.coinDecimal = coinDecimal
    }

    private func update(coinAmount: Decimal?) {
        let prefix = formatHelper.prefix(inputType: sendInputType, rate: rate)

        var mainValue: String? = nil
        if let coinAmount = coinAmount {
            mainValue = formatHelper.formatted(value: coinAmount, inputType: sendInputType, rate: rate)
        }
        let subValue = formatHelper.formattedWithCode(value: coinAmount ?? 0, inputType: sendInputType.reversed, rate: rate)

        view?.set(type: prefix,
                amount: mainValue)

        view?.set(hint: subValue)
    }

    private func updateError(withAvailableBalance availableBalance: Decimal?) {
        self.insufficientAmountWithAvailableBalance = availableBalance

        guard let availableBalance = availableBalance else {
            return
        }

        let errorText = formatHelper.errorValue(availableBalance: availableBalance, inputType: sendInputType, rate: rate)
        view?.set(error: errorText)
    }

}

extension SendAmountPresenter: ISendAmountModule {

    var coinAmount: CoinValue {
        return CoinValue(coinCode: coinCode, value: amount ?? 0)
    }

    var fiatAmount: CurrencyValue? {
        guard let amount = amount else {
            return nil
        }
        return formatHelper.convert(value: amount, currency: currencyManager.baseCurrency, rate: rate)
    }

    func showKeyboard() {
        view?.showKeyboard()
    }

    var validState: Bool {
        return ((amount ?? 0) != 0) && (insufficientAmountWithAvailableBalance == nil)
    }

    func set(amount: Decimal) {
        self.amount = amount
        update(coinAmount: amount)

        delegate?.onChanged()
    }

    func insufficientAmount(availableBalance: Decimal) {
        guard insufficientAmountWithAvailableBalance != availableBalance else {
            // already show this error
            return
        }

        updateError(withAvailableBalance: availableBalance)
    }

    func onValidationSuccess() {
        insufficientAmountWithAvailableBalance = nil
        view?.set(error: nil)
    }

}

extension SendAmountPresenter: ISendAmountViewDelegate {

    func viewDidLoad() {
        rate = interactor.rate(coinCode: coinCode, currencyCode: currencyManager.baseCurrency.code)
        if rate != nil {
            sendInputType = interactor.defaultInputType
            delegate?.onChanged(sendInputType: sendInputType)
        }

        view?.set(switchButtonEnabled: rate != nil)
        update(coinAmount: amount)
    }

    func onSwitchClicked() {
        sendInputType = sendInputType.reversed
        interactor.set(inputType: sendInputType)
        delegate?.onChanged(sendInputType: sendInputType)

        update(coinAmount: amount)

        // if has error, must update it
        updateError(withAvailableBalance: insufficientAmountWithAvailableBalance)
    }

    func onChanged(amountText: String?) {
        let coinAmount: Decimal?
        if let text = amountText, !text.isEmpty {
            // if text contain some number - hide max-button and calculate baseCoin amount
            coinAmount = formatHelper.coinAmount(amountText: text, inputType: sendInputType, rate: rate)
            view?.maxButton(show: false)
        } else {
            // if text is nil or empty - show max-button and set nil baseCoin amount to change UI
            coinAmount = nil
            view?.maxButton(show: true)
        }
        // if new baseCoin amount don't changed just stop update UI
        guard self.amount != coinAmount else {
            return
        }
        self.amount = coinAmount

        // send to delegate 0 to validate and change fee values
        delegate?.onChanged()

        view?.set(hint: formatHelper.formattedWithCode(value: coinAmount ?? 0, inputType: sendInputType.reversed, rate: rate))
    }

    func onMaxClicked() {
        // get maximum available balance from delegate
        guard let availableBalance = delegate?.availableBalance else {
            return
        }
        // Update baseCoin value, UI and hide maxButton
        self.amount = availableBalance
        delegate?.onChanged()

        update(coinAmount: availableBalance)
        view?.maxButton(show: false)
    }

    func validateInputText(text: String) -> Bool {
        if let value = ValueFormatter.instance.parseAnyDecimal(from: text) {
            return value.decimalCount <= interactor.decimal(coinDecimal: coinDecimal, inputType: sendInputType)
        } else {
            return false
        }
    }

}
