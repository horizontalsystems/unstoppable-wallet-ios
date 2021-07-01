import CurrencyKit

extension CurrencyValue {

    var formattedString: String? {
        ValueFormatter.instance.format(currencyValue: self, fractionPolicy: .threshold(high: 1000, low: 0.01))
    }

}