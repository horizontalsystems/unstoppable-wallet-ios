import Foundation

class TransactionViewItemFactory: ITransactionViewItemFactory {
    private let feeCoinProvider: IFeeCoinProvider

    init(feeCoinProvider: IFeeCoinProvider) {
        self.feeCoinProvider = feeCoinProvider
    }

    func viewItem(fromItem item: TransactionItem, lastBlockHeight: Int? = nil, threshold: Int? = nil, rate: CurrencyValue? = nil) -> TransactionViewItem {
        let record = item.record
        let coin = item.wallet.coin

        var status: TransactionStatus = .pending

        if item.record.failed {
            status = .failed
        } else if let blockHeight = record.blockHeight, let lastBlockHeight = lastBlockHeight {
            let threshold = threshold ?? 1
            let confirmations = lastBlockHeight - blockHeight + 1

            if confirmations >= threshold {
                status = .completed
            } else {
                status = .processing(progress: Double(confirmations) / Double(threshold))
            }
        }

        var amount = record.amount
        let incoming = amount > 0
        var from: String?
        var to: String?
        if incoming {
            from = record.from.first(where: { $0.mine == false })?.address
        } else {
            to = record.to.first(where: { $0.mine == false })?.address
        }

        let sentToSelf = !record.from.contains(where: { !$0.mine }) && !record.to.contains(where: { !$0.mine })

        let lockInfo = record.lockInfo
        if let lockInfo = lockInfo {
            amount = lockInfo.lockedValue
        }

        let absoluteAmount: Decimal = abs(amount)
        let currencyValue = rate.map {
            CurrencyValue(currency: $0.currency, value: $0.value * absoluteAmount)
        }
        let coinValue = CoinValue(coin: coin, value: absoluteAmount)
        let feeCoinValue: CoinValue? = item.record.fee.map {
            let feeCoin = feeCoinProvider.feeCoin(coin: coin) ?? coin
            return CoinValue(coin: feeCoin, value: $0)
        }

        return TransactionViewItem(
                wallet: item.wallet,
                transactionHash: record.transactionHash,
                coinValue: coinValue,
                feeCoinValue: feeCoinValue,
                currencyValue: currencyValue,
                from: from,
                to: to,
                incoming: incoming,
                sentToSelf: sentToSelf,
                showFromAddress: showFromAddress(for: coin.type),
                date: record.date,
                status: status,
                rate: rate,
                lockInfo: lockInfo
        )
    }

    private func showFromAddress(for type: CoinType) -> Bool {
        !(type == .bitcoin || type == .bitcoinCash || type == .dash)
    }
}
