import Foundation
import CurrencyKit

class TransactionViewItemFactory: ITransactionViewItemFactory {
    private let feeCoinProvider: IFeeCoinProvider

    init(feeCoinProvider: IFeeCoinProvider) {
        self.feeCoinProvider = feeCoinProvider
    }

    func viewItem(fromRecord record: TransactionRecord, wallet: Wallet, lastBlockInfo: LastBlockInfo? = nil, threshold: Int? = nil, rate: CurrencyValue? = nil) -> TransactionViewItem {
        let coin = wallet.coin
        var status: TransactionStatus = .pending

        if record.failed {
            status = .failed
        } else if let blockHeight = record.blockHeight, let lastBlockHeight = lastBlockInfo?.height {
            let threshold = threshold ?? 1
            let confirmations = lastBlockHeight - blockHeight + 1

            if confirmations >= threshold {
                status = .completed
            } else {
                status = .processing(progress: Double(confirmations) / Double(threshold))
            }
        }

        let currencyValue = rate.map {
            CurrencyValue(currency: $0.currency, value: $0.value * record.amount)
        }
        let coinValue = CoinValue(coin: coin, value: record.amount)
        let feeCoinValue: CoinValue? = record.fee.map {
            let feeCoin = feeCoinProvider.feeCoin(coin: coin) ?? coin
            return CoinValue(coin: feeCoin, value: $0)
        }

        var unlocked = record.lockInfo == nil

        if let lastBlockTimestamp = lastBlockInfo?.timestamp, let lockedUntil = record.lockInfo?.lockedUntil.timeIntervalSince1970 {
            unlocked = Double(lastBlockTimestamp) > lockedUntil
        }

        return TransactionViewItem(
                wallet: wallet,
                record: record,
                transactionHash: record.transactionHash,
                coinValue: coinValue,
                feeCoinValue: feeCoinValue,
                currencyValue: currencyValue,
                from: showFromAddress(for: coin.type) ? record.from : nil,
                to: record.to,
                type: record.type,
                date: record.date,
                status: status,
                rate: rate,
                lockInfo: record.lockInfo,
                unlocked: unlocked,
                conflictingTxHash: record.conflictingHash
        )
    }

    private func showFromAddress(for type: CoinType) -> Bool {
        !(type == .bitcoin || type == .litecoin || type == .bitcoinCash || type == .dash)
    }

    func viewStatus(adapterStates: [Coin: AdapterState], transactionsCount: Int) -> TransactionViewStatus {
        var progress: Int? = nil
        let noTransactions = transactionsCount == 0

        let syncingStates = adapterStates.values.filter {
            if case .syncing = $0 {
                return true
            }
            return false
        }
        let upToDate = syncingStates.count == 0

        if !upToDate {
            var allProgress = 0
            allProgress = syncingStates.reduce(into: 0) { result, state in
                if case let .syncing(progress, _) = state {
                    result += progress
                }
            }
            progress = allProgress / syncingStates.count
        }

        var message: String? = noTransactions && !upToDate ? "transactions.wait_for_sync".localized : "transactions.empty_text".localized
        message = noTransactions ? message : nil
        return TransactionViewStatus(progress: progress, message: message)
    }

}
