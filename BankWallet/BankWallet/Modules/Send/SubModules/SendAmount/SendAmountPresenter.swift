import Foundation

class SendAmountPresenter {
    private let maxCoinDecimal = 8

    weak var view: ISendAmountView?
    weak var delegate: ISendAmountDelegate?

    private let interactor: ISendAmountInteractor

    private let coin: Coin
    private let currency: Currency
    private let rate: Rate?

    private var amount: Decimal?
    private var availableBalance: Decimal?

    private(set) var inputType: SendInputType

    init(coin: Coin, interactor: ISendAmountInteractor) {
        self.coin = coin
        self.interactor = interactor

        currency = interactor.baseCurrency
        rate = interactor.rate(coinCode: coin.code, currencyCode: currency.code)

        if rate == nil {
            inputType = .coin
        } else {
            inputType = interactor.defaultInputType
        }
    }

    private func syncAmountType() {
        switch inputType {
        case .coin: view?.set(amountType: coin.code)
        case .currency: view?.set(amountType: currency.symbol)
        }
    }

    private func syncSwitchButton() {
        view?.set(switchButtonEnabled: rate != nil)
    }

    private func syncMaxButton() {
        view?.set(maxButtonVisible: amount == nil)
    }

    private func syncHint() {
        let hintAmount = amount ?? 0
        let hintInputType = inputType.reversed

        switch hintInputType {
        case .coin:
            view?.set(hint: .coinValue(coinValue: CoinValue(coin: coin, value: hintAmount)))
        case .currency:
            if let rate = rate {
                view?.set(hint: .currencyValue(currencyValue: CurrencyValue(currency: currency, value: hintAmount * rate.value)))
            } else {
                view?.set(hint: nil)
            }
        }
    }

    private func syncAmount() {
        guard let amount = amount else {
            view?.set(amount: nil)
            return
        }

        switch inputType {
        case .coin:
            view?.set(amount: .coinValue(coinValue: CoinValue(coin: coin, value: amount)))
        case .currency:
            if let rate = rate {
                view?.set(amount: .currencyValue(currencyValue: CurrencyValue(currency: currency, value: amount * rate.value)))
            } else {
                fatalError("Invalid state")
            }
        }
    }

    private func syncError() {
        do {
            try validate()
            view?.set(error: nil)
        } catch {
            view?.set(error: error)
        }
    }

    private func validate() throws {
        guard let amount = amount, let availableBalance = availableBalance else {
            return
        }

        if availableBalance < amount {
            switch inputType {
            case .coin:
                throw ValidationError.insufficientBalance(availableBalance: .coinValue(coinValue: CoinValue(coin: coin, value: availableBalance)))
            case .currency:
                if let rate = rate {
                    throw ValidationError.insufficientBalance(availableBalance: .currencyValue(currencyValue: CurrencyValue(currency: currency, value: availableBalance * rate.value)))
                } else {
                    fatalError("Invalid state")
                }
            }

        }
    }

}

extension SendAmountPresenter: ISendAmountModule {

    var validAmount: Decimal? {
        guard let amount = amount, amount > 0 else {
            return nil
        }

        do {
            try validate()
            return amount
        } catch {
            return nil
        }
    }

    var coinAmount: CoinValue {
        return CoinValue(coin: coin, value: amount ?? 0)
    }

    var fiatAmount: CurrencyValue? {
        if let rate = rate {
            return CurrencyValue(currency: currency, value: (amount ?? 0) * rate.value)
        } else {
            return nil
        }
    }

    func showKeyboard() {
        view?.showKeyboard()
    }

    func set(amount: Decimal) {
        self.amount = amount

        syncAmount()
        syncHint()
        syncMaxButton()
        syncError()

        delegate?.onChangeAmount()
    }

    func set(availableBalance: Decimal) {
        self.availableBalance = availableBalance
        syncError()
    }

}

extension SendAmountPresenter: ISendAmountViewDelegate {

    func viewDidLoad() {
        syncAmountType()
        syncSwitchButton()
        syncHint()
    }

    func onSwitchClicked() {
        inputType = inputType.reversed
        interactor.set(inputType: inputType)
        delegate?.onChange(inputType: inputType)

        syncAmountType()
        syncAmount()
        syncHint()
        syncError()
    }

    func onChanged(amountText: String?) {
        let enteredAmount = ValueFormatter.instance.parseAnyDecimal(from: amountText)

        switch inputType {
        case .coin:
            amount = enteredAmount
        case .currency:
            if let enteredAmount = enteredAmount {
                if let rate = rate {
                    amount = enteredAmount / rate.value
                } else {
                    fatalError("Invalid state")
                }
            } else {
                amount = nil
            }
        }

        syncHint()
        syncMaxButton()
        syncError()

        delegate?.onChangeAmount()
    }

    func onMaxClicked() {
        guard let availableBalance = availableBalance else {
            return
        }

        amount = availableBalance

        syncAmount()
        syncHint()
        syncMaxButton()
        syncError()

        delegate?.onChangeAmount()
    }

    func isValid(text: String) -> Bool {
        guard let value = ValueFormatter.instance.parseAnyDecimal(from: text) else {
            return false
        }

        switch inputType {
        case .coin: return value.decimalCount <= min(coin.decimal, maxCoinDecimal)
        case .currency: return value.decimalCount <= currency.decimal
        }
    }

}

extension SendAmountPresenter {

    private enum ValidationError: Error, LocalizedError {
        case insufficientBalance(availableBalance: AmountInfo)

        var errorDescription: String? {
            switch self {
            case .insufficientBalance(let availableBalance):
                return "send.amount_error.balance".localized(availableBalance.formattedString ?? "")
            }
        }
    }

}
