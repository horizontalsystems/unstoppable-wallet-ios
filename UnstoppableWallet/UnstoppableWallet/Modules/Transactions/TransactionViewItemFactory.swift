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

    func viewItem(fromRecord record: TransactionRecord, wallet: Wallet, lastBlockInfo: LastBlockInfo? = nil, mainAmountCurrencyValue: CurrencyValue? = nil) -> TransactionViewItem {
        TransactionViewItem(
                wallet: wallet,
                record: record,
                type: record.type(lastBlockInfo: lastBlockInfo),
                date: record.date,
                status: record.status(lastBlockHeight: lastBlockInfo?.height),
                mainAmountCurrencyValue: mainAmountCurrencyValue
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
