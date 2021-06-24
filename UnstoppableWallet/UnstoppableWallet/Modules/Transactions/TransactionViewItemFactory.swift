import Foundation
import CurrencyKit
import CoinKit

class TransactionViewItemFactory: ITransactionViewItemFactory {

    func filterItems(wallets: [Wallet]) -> [FilterHeaderView.ViewItem] {
        if wallets.count < 2 {
            return []
        } else {
            return [.all] + wallets.map { .item(title: $0.coin.code) }
        }
    }

    func viewItem(fromRecord record: TransactionRecord, wallet: Wallet, lastBlockInfo: LastBlockInfo? = nil, mainCoinRate: CurrencyValue? = nil) -> TransactionViewItem {
        var currencyValue: CurrencyValue? = nil

        if let coin = record.mainCoin, let amount = record.mainAmount {
            currencyValue = mainCoinRate.map { CurrencyValue(currency: $0.currency, value: $0.value * amount) }
        }

        return TransactionViewItem(
                wallet: wallet,
                record: record,
                type: record.type(lastBlockInfo: lastBlockInfo),
                date: record.date,
                status: record.status(lastBlockHeight: lastBlockInfo?.height),
                mainAmountCurrencyValue: currencyValue
        )
    }

    func viewStatus(adapterStates: [Coin: AdapterState], transactionsCount: Int) -> TransactionViewStatus {
        let noTransactions = transactionsCount == 0
        var upToDate = true

        adapterStates.values.forEach {
            if case .syncing = $0 {
                upToDate = false
            }
        }

        return TransactionViewStatus(showProgress: !upToDate, showMessage: noTransactions)
    }

}
