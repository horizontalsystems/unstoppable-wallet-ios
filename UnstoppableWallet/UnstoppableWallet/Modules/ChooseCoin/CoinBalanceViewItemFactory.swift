import Foundation

class CoinBalanceViewItemFactory: ICoinBalanceViewItemFactory {

    func viewItem(item: CoinBalanceItem) -> CoinBalanceViewItem {
        let balance = item.balance.flatMap {
            ValueFormatter.instance.format(coinValue: CoinValue(coin: item.coin, value: $0), fractionPolicy: .threshold(high: 0.01, low: 0))
        }

        return CoinBalanceViewItem(coin: item.coin, balance: balance)
    }

}
