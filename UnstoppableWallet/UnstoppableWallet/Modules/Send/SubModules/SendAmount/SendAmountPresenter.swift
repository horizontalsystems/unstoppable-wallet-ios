import Foundation
import CurrencyKit
import MarketKit

class SendAmountPresenter {
    private let maxCoinDecimal = 8

    weak var view: ISendAmountView?
    weak var delegate: ISendAmountDelegate?

    private let interactor: ISendAmountInteractor
    private let decimalParser: IAmountDecimalParser

    private let platformCoin: PlatformCoin
    let currency: Currency

    private var availableAmount: Decimal?
    private var maximumAmount: Decimal?
    private var minimumAmount: Decimal?
    private var minimumRequiredBalance: Decimal = 0

    private(set) var inputType: SendInputType = .coin

    private var amount: Decimal?

    var sendAmountInfo: SendAmountInfo = .notEntered
    var rateValue: Decimal?

    init(platformCoin: PlatformCoin, interactor: ISendAmountInteractor, decimalParser: IAmountDecimalParser) {
        self.platformCoin = platformCoin
        self.interactor = interactor
        self.decimalParser = decimalParser

        currency = interactor.baseCurrency
    }

    private func syncAmountType() {
        view?.setAmountColor(inputType: inputType)

        switch inputType {
        case .coin: view?.set(prefix: nil)
        case .currency: view?.set(prefix: currency.symbol)
        }
    }

    private func syncSwitchButton() {
        view?.set(switchButtonEnabled: rateValue != nil)
    }

    private func syncMaxButton() {
        guard let availableAmount = availableAmount, amount == nil else {
            view?.set(maxButtonVisible: false)
            return
        }
        let hasSpendableBalance = availableAmount > 0
        view?.set(maxButtonVisible: hasSpendableBalance)
    }

    private func syncHint() {
        let hintAmount = amount ?? 0

        view?.set(hint: secondaryAmountInfo(amount: hintAmount))
        view?.setHintColor(inputType: inputType.reversed)
    }

    private func syncAmount() {
        guard let amount = amount else {
            view?.set(amount: nil)
            return
        }

        view?.set(amount: primaryAmountInfo(amount: amount))
    }

    private func syncAvailableAmount() {
        guard let availableAmount = availableAmount else {
            view?.set(availableAmount: nil)
            return
        }

        view?.set(availableAmount: primaryAmountInfo(amount: availableAmount))
    }

    private func primaryAmountInfo(amount: Decimal) -> AmountInfo {
        switch inputType {
        case .coin:
            return .coinValue(coinValue: CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: amount))
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
            return .coinValue(coinValue: CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: amount))
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

        if let availableAmount = availableAmount {
            if availableAmount < amount {
                switch inputType {
                case .coin:
                    throw ValidationError.insufficientBalance(availableAmount: .coinValue(coinValue: CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: availableAmount)))
                case .currency:
                    if let rateValue = rateValue {
                        throw ValidationError.insufficientBalance(availableAmount: .currencyValue(currencyValue: CurrencyValue(currency: currency, value: availableAmount * rateValue)))
                    } else {
                        fatalError("Invalid state")
                    }
                }
            }
        }

        if let maximumAmount = maximumAmount {
            if maximumAmount < amount {
                switch inputType {
                case .coin:
                    throw ValidationError.maximumAmountExceeded(maximumAmount: .coinValue(coinValue: CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: maximumAmount)))
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
                    throw ValidationError.tooFewAmount(minimumAmount: .coinValue(coinValue: CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: minimumAmount)))
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
        sendAmountInfo = .entered(amount: amount)

        syncAmount()
        syncHint()
        syncMaxButton()
        syncError()

        delegate?.onChangeAmount()
    }

    func set(rateValue: Decimal?) {
        self.rateValue = rateValue

        syncSwitchButton()

        if rateValue == nil {
            set(inputType: .coin)
            delegate?.onChange(inputType: inputType)
        }
    }

    func set(inputType: SendInputType) {
        self.inputType = inputType

        syncAvailableAmount()
        syncAmountType()
        syncAmount()
        syncHint()
        syncError()
    }

    func set(availableBalance: Decimal) {
        availableAmount = availableBalance - minimumRequiredBalance
        syncMaxButton()
        syncAvailableAmount()
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
        availableAmount = availableAmount.flatMap { $0 - minimumRequiredBalance }
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

        syncAvailableAmount()
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

        if let coinAmount = amount {
            sendAmountInfo = .entered(amount: coinAmount)
        } else {
            sendAmountInfo = .notEntered
        }

        syncHint()
        syncMaxButton()
        syncError()
    }

    func didChangeAmount() {
        delegate?.onChangeAmount()
    }

    func onMaxClicked() {
        guard let availableAmount = availableAmount else {
            return
        }

        amount = availableAmount
        sendAmountInfo = .max

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
        case .coin: return value.decimalCount <= min(platformCoin.decimal, maxCoinDecimal)
        case .currency: return value.decimalCount <= currency.decimal
        }
    }

}

extension SendAmountPresenter {

    enum ValidationError: Error, LocalizedError {
        case emptyValue
        case insufficientBalance(availableAmount: AmountInfo)
        case noMinimumRequiredBalance(minimumRequiredBalance: AmountInfo)
        case maximumAmountExceeded(maximumAmount: AmountInfo)
        case tooFewAmount(minimumAmount: AmountInfo)

        var errorDescription: String? {
            switch self {
            case .emptyValue:
                return "send.amount_error.empty".localized
            case .insufficientBalance:
                return "send.amount_error.balance".localized
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
