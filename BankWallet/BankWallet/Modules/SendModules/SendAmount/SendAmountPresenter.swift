import Foundation

class SendAmountPresenter {
    private let interactor: ISendAmountInteractor
    private let sendAmountPresenterHelper: SendAmountPresenterHelper

    weak var view: ISendAmountView?
    weak var presenterDelegate: ISendAmountPresenterDelegate?

    var sendInputType: SendInputType = .coin
    var coinAmount: Decimal?
    var switchButtonEnabled: Bool = false

    var rate: Rate?
    let coinCode: CoinCode
    let coinDecimal: Int
    let currencyCode: String

    init(interactor: ISendAmountInteractor, sendAmountPresenterHelper: SendAmountPresenterHelper, coinCode: CoinCode, coinDecimal: Int, currencyCode: String) {
        self.interactor = interactor
        self.sendAmountPresenterHelper = sendAmountPresenterHelper

        self.coinCode = coinCode
        self.coinDecimal = coinDecimal
        self.currencyCode = currencyCode
    }

    private func update(coinAmount: Decimal?) {
        let prefix = sendAmountPresenterHelper.prefix(inputType: sendInputType, rate: rate)
        let mainValue = sendAmountPresenterHelper.mainValue(coinAmount: coinAmount, inputType: sendInputType, rate: rate)
        let subValue = sendAmountPresenterHelper.subValue(coinAmount: coinAmount ?? 0, inputType: sendInputType, rate: rate)

        view?.set(type: prefix,
                amount: mainValue)

        view?.set(hint: subValue, error: nil)
    }

}

extension SendAmountPresenter {

    func viewDidLoad() {
        rate = interactor.rate(coinCode: coinCode, currencyCode: currencyCode)
        if rate != nil {
            sendInputType = interactor.defaultInputType
        }

        view?.set(switchButtonEnabled: rate != nil)
        update(coinAmount: coinAmount)
    }

    func showKeyboard() {
        view?.showKeyboard()
    }

}

extension SendAmountPresenter: ISendAmountViewDelegate {

    func onSwitchClicked() {
        sendInputType = sendInputType.reversed

        update(coinAmount: coinAmount)
        print("switch clicked")
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
        presenterDelegate?.onChanged(amount: coinAmount)

        view?.set(hint: sendAmountPresenterHelper.subValue(coinAmount: coinAmount ?? 0, inputType: sendInputType, rate: rate), error: nil)
    }

    func onMaxClicked() {
        // get maximum available balance from delegate
        guard let availableBalance = presenterDelegate?.availableBalance else {
            return
        }
        // Update baseCoin value, UI and hide maxButton
        self.coinAmount = availableBalance
        presenterDelegate?.onChanged(amount: coinAmount)

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
