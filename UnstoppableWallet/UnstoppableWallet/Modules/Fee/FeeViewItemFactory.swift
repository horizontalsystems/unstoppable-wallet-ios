import CurrencyKit

class FeeViewItemFactory: IFeeViewItemFactory {

    func viewItem(coinValue: CoinValue, currencyValue: CurrencyValue?, reversed: Bool) -> FeeViewItem {
        let coinValue = ValueFormatter.instance.format(coinValue: coinValue)
        let currencyValue = currencyValue.flatMap { ValueFormatter.instance.format(currencyValue: $0) }

        var array = [coinValue, currencyValue].compactMap { $0 }
        if reversed {
            array.reverse()
        }

        return FeeViewItem(value: array.joined(separator: " | "))
    }

}
