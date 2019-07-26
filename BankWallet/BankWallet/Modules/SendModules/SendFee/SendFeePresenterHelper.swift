import Foundation

class SendFeePresenterHelper {
    let coinCode: CoinCode
    let coinDecimal: Int = 8
    let currency: Currency
    let currencyDecimal: Int = 2

    init(coinCode: CoinCode, currency: Currency) {
        self.coinCode = coinCode
        self.currency = currency
    }

    func mainValue(coinAmount: Decimal?, inputType: SendInputType, rate: Rate?) -> String? {
        guard let amount = coinAmount else {
            return nil
        }
        if inputType == .currency {
            guard let value = rate.map({ amount * $0.value }) else {
                return nil
            }
            let rounded = ValueFormatter.instance.round(value: value, scale: currencyDecimal, roundingMode: .down)
            return ValueFormatter.instance.format(amount: rounded)
        }
        let rounded = ValueFormatter.instance.round(value: amount, scale: coinDecimal, roundingMode: .down)
        return ValueFormatter.instance.format(amount: rounded)
    }

    func subValue(coinAmount: Decimal, inputType: SendInputType, rate: Rate?) -> String? {
        if inputType == .coin {
            guard let value = rate.map({ coinAmount * $0.value }) else {
                return nil
            }
            return ValueFormatter.instance.format(currencyValue: CurrencyValue(currency: currency, value: value))
        }
        return ValueFormatter.instance.format(coinValue: CoinValue(coinCode: coinCode, value: coinAmount))
    }

    func errorValue(availableBalance: Decimal, inputType: SendInputType, rate: Rate?) -> String? {
        if inputType == .currency {
            guard let value = rate.map({ availableBalance * $0.value }) else {
                return "send.amount_error.balance".localized("")
            }
            let rounded = ValueFormatter.instance.round(value: value, scale: currencyDecimal, roundingMode: .down)
            return "send.amount_error.balance".localized(ValueFormatter.instance.format(currencyValue: CurrencyValue(currency: currency, value: rounded)) ?? "")
        }

        let rounded = ValueFormatter.instance.round(value: availableBalance, scale: coinDecimal, roundingMode: .down)
        return "send.amount_error.balance".localized(ValueFormatter.instance.format(coinValue: CoinValue(coinCode: coinCode, value: rounded)) ?? "")
    }

    func coinAmount(amountText: String, inputType: SendInputType, rate: Rate?) -> Decimal? {
        let amount = ValueFormatter.instance.parseAnyDecimal(from: amountText) ?? 0

        if inputType == .coin {
            return amount
        }
        guard let rate = rate, rate.value != 0 else {
            return nil
        }
        return ValueFormatter.instance.round(value: amount / rate.value, scale: coinDecimal, roundingMode: .down)
    }

}
