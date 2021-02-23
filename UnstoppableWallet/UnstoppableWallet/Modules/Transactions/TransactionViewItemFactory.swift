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

    func viewItem(fromRecord record: TransactionRecord, wallet: Wallet, lastBlockInfo: LastBlockInfo? = nil, rate: CurrencyValue? = nil) -> TransactionViewItem {
        TransactionViewItem(
                wallet: wallet,
                record: record,
                transactionHash: record.transactionHash,
                coinValue: CoinValue(coin: wallet.coin, value: record.amount),
                currencyValue: rate.map { CurrencyValue(currency: $0.currency, value: $0.value * record.amount) },
                type: record.type,
                date: record.date,
                status: record.status(lastBlockHeight: lastBlockInfo?.height),
                lockState: record.lockState(lastBlockTimestamp: lastBlockInfo?.timestamp),
                conflictingTxHash: record.conflictingHash
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
