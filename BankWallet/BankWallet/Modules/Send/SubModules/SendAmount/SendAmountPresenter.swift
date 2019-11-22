import Foundation

class SendAmountPresenter {
    private let maxCoinDecimal = 8

    weak var view: ISendAmountView?
    weak var delegate: ISendAmountDelegate?

    private let interactor: ISendAmountInteractor
    private let decimalParser: ISendAmountDecimalParser

    private let coin: Coin
    private let currency: Currency
    private let rateValue: Decimal?

    private var amount: Decimal?
    private var availableBalance: Decimal?
    private var maximumAmount: Decimal?
    private var minimumAmount: Decimal?
    private var minimumRequiredBalance: Decimal = 0

    private(set) var inputType: SendInputType

    init(coin: Coin, interactor: ISendAmountInteractor, decimalParser: ISendAmountDecimalParser) {
        self.coin = coin
        self.interactor = interactor
        self.decimalParser = decimalParser

        currency = interactor.baseCurrency
        rateValue = interactor.nonExpiredRateValue(coinCode: coin.code, currencyCode: currency.code)

        if rateValue == nil {
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
        view?.set(switchButtonEnabled: rateValue != nil)
    }

    private func syncMaxButton() {
        guard let availableBalance = availableBalance, amount == nil else {
            view?.set(maxButtonVisible: false)
            return
        }
        let hasSpendableBalance = availableBalance - minimumRequiredBalance > 0
        view?.set(maxButtonVisible: hasSpendableBalance)
    }

    private func syncHint() {
        let hintAmount = amount ?? 0

        view?.set(hint: secondaryAmountInfo(amount: hintAmount))
    }

    private func syncAmount() {
        guard let amount = amount else {
            view?.set(amount: nil)
            return
        }

        view?.set(amount: primaryAmountInfo(amount: amount))
    }

    private func syncAvailableBalance() {
        guard let availableBalance = availableBalance else {
            view?.set(availableBalance: nil)
            return
        }

        view?.set(availableBalance: primaryAmountInfo(amount: availableBalance))
    }

    private func primaryAmountInfo(amount: Decimal) -> AmountInfo {
        switch inputType {
        case .coin:
            return .coinValue(coinValue: CoinValue(coin: coin, value: amount))
        case .currency:
            if let rateValue = rateValue {
                return .currencyValue(currencyValue: CurrencyValue(currency: currency, value: amount * rateValue))
            } else {
                fatalError("Invalid state")
            }
        }
    }

    private func secondaryAmountInfo(amount: Decimal) -> AmountInfo? {
        switch inputType.reversed {
        case .coin:
            return .coinValue(coinValue: CoinValue(coin: coin, value: amount))
        case .currency:
            if let rateValue = rateValue {
                return .currencyValue(currencyValue: CurrencyValue(currency: currency, value: amount * rateValue))
            } else {
                return nil
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
        guard let amount = amount, !amount.isZero else {
            return
        }

        if let availableBalance = availableBalance {
            if availableBalance < amount {
                switch inputType {
                case .coin:
                    throw ValidationError.insufficientBalance(availableBalance: .coinValue(coinValue: CoinValue(coin: coin, value: availableBalance)))
                case .currency:
                    if let rateValue = rateValue {
                        throw ValidationError.insufficientBalance(availableBalance: .currencyValue(currencyValue: CurrencyValue(currency: currency, value: availableBalance * rateValue)))
                    } else {
                        fatalError("Invalid state")
                    }
                }
            }

            if availableBalance - amount < minimumRequiredBalance {
                throw ValidationError.noMinimumRequiredBalance(minimumRequiredBalance: .coinValue(coinValue: CoinValue(coin: coin, value: minimumRequiredBalance)))
            }
        }

        if let maximumAmount = maximumAmount {
            if maximumAmount < amount {
                switch inputType {
                case .coin:
                    throw ValidationError.maximumAmountExceeded(maximumAmount: .coinValue(coinValue: CoinValue(coin: coin, value: maximumAmount)))
                case .currency:
                    if let rateValue = rateValue {
                        throw ValidationError.maximumAmountExceeded(maximumAmount: .currencyValue(currencyValue: CurrencyValue(currency: currency, value: maximumAmount * rateValue)))
                    } else {
                        fatalError("Invalid state")
                    }
                }
            }
        }

        if let minimumAmount = minimumAmount {
            if minimumAmount > amount {
                switch inputType {
                case .coin:
                    throw ValidationError.tooFewAmount(minimumAmount: .coinValue(coinValue: CoinValue(coin: coin, value: minimumAmount)))
                case .currency:
                    if let rateValue = rateValue {
                        throw ValidationError.tooFewAmount(minimumAmount: .currencyValue(currencyValue: CurrencyValue(currency: currency, value: minimumAmount * rateValue)))
                    } else {
                        fatalError("Invalid state")
                    }
                }
            }
        }
    }

}

extension SendAmountPresenter: ISendAmountModule {

    func validAmount() throws -> Decimal {
        guard let amount = amount, amount > 0 else {
            throw ValidationError.emptyValue
        }

        try validate()

        return amount
    }

    var currentAmount: Decimal {
        amount ?? 0
    }

    func primaryAmountInfo() throws -> AmountInfo {
        primaryAmountInfo(amount: try validAmount())
    }

    func secondaryAmountInfo() throws -> AmountInfo? {
        secondaryAmountInfo(amount: try validAmount())
    }

    func showKeyboard() {
        view?.showKeyboard()
    }

    func set(loading: Bool) {
        view?.set(loading: loading)
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
        syncMaxButton()
        syncAvailableBalance()
        syncError()
    }

    func set(maximumAmount: Decimal?) {
        self.maximumAmount = maximumAmount
        syncError()
    }

    func set(minimumAmount: Decimal) {
        self.minimumAmount = minimumAmount
        syncError()
    }

    func set(minimumRequiredBalance: Decimal) {
        self.minimumRequiredBalance = minimumRequiredBalance
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

        syncAvailableBalance()
        syncAmountType()
        syncAmount()
        syncHint()
        syncError()
    }

    func willChangeAmount(text: String?) {
        let enteredAmount = decimalParser.parseAnyDecimal(from: text)

        switch inputType {
        case .coin:
            amount = enteredAmount
        case .currency:
            if let enteredAmount = enteredAmount {
                if let rateValue = rateValue {
                    amount = enteredAmount / rateValue
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
    }

    func didChangeAmount() {
        delegate?.onChangeAmount()
    }

    func onMaxClicked() {
        guard let availableBalance = availableBalance else {
            return
        }

        amount = availableBalance - minimumRequiredBalance

        syncAmount()
        syncHint()
        syncMaxButton()
        syncError()

        delegate?.onChangeAmount()
    }

    func isValid(text: String) -> Bool {
        guard let value = decimalParser.parseAnyDecimal(from: text) else {
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
        case emptyValue
        case insufficientBalance(availableBalance: AmountInfo)
        case noMinimumRequiredBalance(minimumRequiredBalance: AmountInfo)
        case maximumAmountExceeded(maximumAmount: AmountInfo)
        case tooFewAmount(minimumAmount: AmountInfo)

        var errorDescription: String? {
            switch self {
            case .emptyValue:
                return "send.amount_error.empty".localized
            case .insufficientBalance(let availableBalance):
                return "send.amount_error.balance".localized(availableBalance.formattedString ?? "")
            case .noMinimumRequiredBalance(let minimumRequiredBalance):
                return "send.amount_error.min_required_balance".localized(minimumRequiredBalance.formattedString ?? "")
            case .maximumAmountExceeded(let maximumAmount):
                return "send.amount_error.maximum_amount".localized(maximumAmount.formattedString ?? "")
            case .tooFewAmount(let minimumAmount):
                return "send.amount_error.minimum_amount".localized(minimumAmount.formattedString ?? "")
            }
        }
    }

}
