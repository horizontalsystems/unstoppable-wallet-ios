import Foundation

class SendAmountPresenterHelper {
    let coinCode: CoinCode
    let coinDecimal: Int
    let currency: Currency
    let currencyDecimal: Int

    init(coinCode: CoinCode, coinDecimal: Int, currency: Currency, currencyDecimal: Int) {
        self.coinCode = coinCode
        self.coinDecimal = coinDecimal
        self.currency = currency
        self.currencyDecimal = currencyDecimal
    }

    func prefix(inputType: SendInputType, rate: Rate?) -> String? {
        if inputType == .coin {
            return coinCode
        }
        guard rate != nil else {
            return nil
        }
        return currency.symbol
    }


    func formatted(value: Decimal, inputType: SendInputType, rate: Rate?) -> String? {
        var value = value
        let scale: Int
        if inputType == .currency {
            guard let currencyValue = rate.map({ value * $0.value }) else {
                return nil
            }
            value = currencyValue
            scale = currencyDecimal
        } else {
            scale = coinDecimal
        }
        let rounded = ValueFormatter.instance.round(value: value, scale: scale, roundingMode: .down)
        return ValueFormatter.instance.format(amount: rounded)
    }

    func formattedWithCode(value: Decimal, inputType: SendInputType, rate: Rate?) -> String? {
        if inputType == .currency {
            guard let value = rate.map({ value * $0.value }) else {
                return nil
            }
            return ValueFormatter.instance.format(currencyValue: CurrencyValue(currency: currency, value: value))
        }
        return ValueFormatter.instance.format(coinValue: CoinValue(coinCode: coinCode, value: value))
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
