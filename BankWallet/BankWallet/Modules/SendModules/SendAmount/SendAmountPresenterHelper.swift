import Foundation

class SendAmountPresenterHelper {
    let coinCode: CoinCode
    let coinDecimal: Int = 8
    let currency: Currency
    let currencyDecimal: Int = 2

    init(coinCode: CoinCode, currency: Currency) {
        self.coinCode = coinCode
        self.currency = currency
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
