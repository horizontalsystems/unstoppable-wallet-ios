import Foundation

class BalanceViewItemFactory: IBalanceViewItemFactory {

    func viewItem(from item: BalanceItem, currency: Currency?) -> BalanceViewItem {
        var exchangeValue: CurrencyValue?
        var currencyValue: CurrencyValue?

        if let currency = currency, let rate = item.rate {
            exchangeValue = CurrencyValue(currency: currency, value: rate.value)
            currencyValue = CurrencyValue(currency: currency, value: item.balance * rate.value)
        }

        return BalanceViewItem(
                coin: item.coin,
                coinValue: CoinValue(coinCode: item.coin.code, value: item.balance),
                exchangeValue: exchangeValue,
                currencyValue: currencyValue,
                state: item.state,
                rateExpired: item.rate?.expired ?? false
        )
    }

    func headerViewItem(from items: [BalanceItem], currency: Currency?) -> BalanceHeaderViewItem {
        var currencyValue: CurrencyValue?
        var upToDate = true

        if let currency = currency {
            var total: Decimal = 0

            for item in items {
                if let rate = item.rate {
                    total += item.balance * rate.value

                    if rate.expired {
                        upToDate = false
                    }
                } else {
                    upToDate = false
                }

                if case .synced = item.state {
                    // do nothing
                } else {
                    upToDate = false
                }
            }

            currencyValue = CurrencyValue(currency: currency, value: total)
        }

        return BalanceHeaderViewItem(
                currencyValue: currencyValue,
                upToDate: upToDate
        )
    }

}
