import CurrencyKit

extension CurrencyValue {

    var abs: CurrencyValue {
        CurrencyValue(currency: currency, value: value.magnitude)
    }

}