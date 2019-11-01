import Foundation

class BalanceViewItemFactory: IBalanceViewItemFactory {

    func viewItem(item: BalanceItem, currency: Currency) -> BalanceViewItem {
        var exchangeValue: CurrencyValue?
        var currencyValue: CurrencyValue?

        if let marketInfo = item.marketInfo {
            exchangeValue = CurrencyValue(currency: currency, value: marketInfo.rate)

            if let balance = item.balance {
                currencyValue = CurrencyValue(currency: currency, value: balance * marketInfo.rate)
            }
        }

        return BalanceViewItem(
                wallet: item.wallet,
                coin: item.wallet.coin,
                coinValue: CoinValue(coin: item.wallet.coin, value: item.balance ?? 0),
                exchangeValue: exchangeValue,
                diff: item.marketInfo?.diff,
                currencyValue: currencyValue,
                state: item.state ?? .notReady,
                marketInfoExpired: item.marketInfo?.expired ?? false,
                chartInfoState: item.chartInfoState
        )
    }

    func headerViewItem(items: [BalanceItem], currency: Currency) -> BalanceHeaderViewItem {
        var total: Decimal = 0
        var upToDate = true

        for item in items {
            if let balance = item.balance, let marketInfo = item.marketInfo {
                total += balance * marketInfo.rate

                if marketInfo.expired {
                    upToDate = false
                }
            }

            if case .synced = item.state {
                // do nothing
            } else {
                upToDate = false
            }
        }

        let currencyValue = CurrencyValue(currency: currency, value: total)

        return BalanceHeaderViewItem(
                currencyValue: currencyValue,
                upToDate: upToDate
        )
    }

}
