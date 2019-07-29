import Foundation

class SendAmountPresenter {
    private let interactor: ISendAmountInteractor
    private let sendAmountPresenterHelper: SendAmountPresenterHelper

    private let coinCode: CoinCode
    private let coinDecimal: Int
    private let currencyCode: String

    weak var view: ISendAmountView?
    weak var presenterDelegate: ISendAmountPresenterDelegate?

    private var sendInputType: SendInputType = .coin

    var coinAmount: Decimal?
    private var switchButtonEnabled: Bool = false
    private var rate: Rate?
    private var error: SendStateError?

    init(interactor: ISendAmountInteractor, sendAmountPresenterHelper: SendAmountPresenterHelper, coinCode: CoinCode, coinDecimal: Int, currencyCode: String) {
        self.interactor = interactor
        self.sendAmountPresenterHelper = sendAmountPresenterHelper

        self.coinCode = coinCode
        self.coinDecimal = coinDecimal
        self.currencyCode = currencyCode
    }

    private func update(coinAmount: Decimal?) {
        let prefix = sendAmountPresenterHelper.prefix(inputType: sendInputType, rate: rate)

        var mainValue: String? = nil
        if let coinAmount = coinAmount {
            mainValue = sendAmountPresenterHelper.formatted(value: coinAmount, inputType: sendInputType, rate: rate)
        }
        let subValue = sendAmountPresenterHelper.formattedWithCode(value: coinAmount ?? 0, inputType: sendInputType.reversed, rate: rate)

        view?.set(type: prefix,
                amount: mainValue)

        view?.set(hint: subValue)
    }

    private func updateError(error: SendStateError?) {
        if let error = error, case let .insufficientAmount(availableBalance) = error {
            self.error = error

            let errorText = sendAmountPresenterHelper.errorValue(availableBalance: availableBalance, inputType: sendInputType, rate: rate)
            view?.set(error: errorText)
        }
    }

}

extension SendAmountPresenter {

    func viewDidLoad() {
        rate = interactor.rate(coinCode: coinCode, currencyCode: currencyCode)
        if rate != nil {
            sendInputType = interactor.defaultInputType
            presenterDelegate?.onChanged(sendInputType: sendInputType)
        }

        view?.set(switchButtonEnabled: rate != nil)
        update(coinAmount: coinAmount)
    }

    func showKeyboard() {
        view?.showKeyboard()
    }

    func onValidation(error: SendStateError) {
        guard self.error != error else {
            // already show this error
            return
        } 

        updateError(error: error)
    }

    func onValidationSuccess() {
        error = nil
        view?.set(error: nil)
    }

}

extension SendAmountPresenter: ISendAmountViewDelegate {

    func onSwitchClicked() {
        sendInputType = sendInputType.reversed
        interactor.set(inputType: sendInputType)
        presenterDelegate?.onChanged(sendInputType: sendInputType)

        update(coinAmount: coinAmount)

        // if has error, must update it
        updateError(error: error)
    }

    func onChanged(amountText: String?) {
        let coinAmount: Decimal?
        if let text = amountText, !text.isEmpty {
            // if text contain some number - hide max-button and calculate baseCoin amount
            coinAmount = sendAmountPresenterHelper.coinAmount(amountText: text, inputType: sendInputType, rate: rate)
            view?.maxButton(show: false)
        } else {
            // if text is nil or empty - show max-button and set nil baseCoin amount to change UI
            coinAmount = nil
            view?.maxButton(show: true)
        }
        // if new baseCoin amount don't changed just stop update UI
        guard self.coinAmount != coinAmount else {
            return
        }
        self.coinAmount = coinAmount

        // send to delegate 0 to validate and change fee values
        presenterDelegate?.onChanged()

        view?.set(hint: sendAmountPresenterHelper.formattedWithCode(value: coinAmount ?? 0, inputType: sendInputType.reversed, rate: rate))
    }

    func onMaxClicked() {
        // get maximum available balance from delegate
        guard let availableBalance = presenterDelegate?.availableBalance else {
            return
        }
        // Update baseCoin value, UI and hide maxButton
        self.coinAmount = availableBalance
        presenterDelegate?.onChanged()

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
