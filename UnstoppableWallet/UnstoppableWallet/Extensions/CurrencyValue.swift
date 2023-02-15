import CurrencyKit

extension CurrencyValue {

    var formattedFull: String? {
        ValueFormatter.instance.formatFull(currencyValue: self)
    }

}
