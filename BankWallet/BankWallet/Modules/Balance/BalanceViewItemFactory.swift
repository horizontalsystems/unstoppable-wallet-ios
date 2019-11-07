import Foundation

class BalanceViewItemFactory: IBalanceViewItemFactory {

    func viewItem(item: BalanceItem, currency: Currency) -> BalanceViewItem {
        let balanceTotal = item.balanceTotal ?? 0
        let balanceLocked = item.balanceLocked ?? 0

        var exchangeValue: CurrencyValue?
        var currencyValueTotal: CurrencyValue?
        var currencyValueLocked: CurrencyValue?

        if let marketInfo = item.marketInfo {
            exchangeValue = CurrencyValue(currency: currency, value: marketInfo.rate)
            currencyValueTotal = CurrencyValue(currency: currency, value: balanceTotal * marketInfo.rate)
            currencyValueLocked = CurrencyValue(currency: currency, value: balanceLocked * marketInfo.rate)
        }

        return BalanceViewItem(
                wallet: item.wallet,
                coin: item.wallet.coin,
                coinValue: CoinValue(coin: item.wallet.coin, value: balanceTotal),
                exchangeValue: exchangeValue,
                diff: item.marketInfo?.diff,
                currencyValue: currencyValueTotal,
                state: item.state ?? .notReady,
                marketInfoExpired: item.marketInfo?.expired ?? false,
                chartInfoState: item.chartInfoState,
                coinValueLocked: CoinValue(coin: item.wallet.coin, value: balanceLocked),
                currencyValueLocked: currencyValueLocked
        )
    }

    func headerViewItem(items: [BalanceItem], currency: Currency) -> BalanceHeaderViewItem {
        var total: Decimal = 0
        var upToDate = true

        items.forEach { item in
            if let balanceTotal = item.balanceTotal, let marketInfo = item.marketInfo {
                total += balanceTotal * marketInfo.rate

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
