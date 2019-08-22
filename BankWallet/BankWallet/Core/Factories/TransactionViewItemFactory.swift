import Foundation

class TransactionViewItemFactory: ITransactionViewItemFactory {
    private let feeCoinProvider: FeeCoinProvider

    init(feeCoinProvider: FeeCoinProvider) {
        self.feeCoinProvider = feeCoinProvider
    }

    func viewItem(fromItem item: TransactionItem, lastBlockHeight: Int? = nil, threshold: Int? = nil, rate: CurrencyValue? = nil) -> TransactionViewItem {
        let record = item.record
        let coin = item.wallet.coin

        let feeCoinValue: CoinValue? = item.record.fee.map {
            let feeCoin = feeCoinProvider.feeCoinData(coin: coin)?.0 ?? coin
            return CoinValue(coin: feeCoin, value: $0)
        }

        let currencyValue = rate.map { CurrencyValue(currency: $0.currency, value: $0.value * record.amount) }

        var status: TransactionStatus = .pending

        if let blockHeight = record.blockHeight, let lastBlockHeight = lastBlockHeight {
            let threshold = threshold ?? 1
            let confirmations = lastBlockHeight - blockHeight + 1

            if confirmations >= threshold {
                status = .completed
            } else {
                status = .processing(progress: Double(confirmations) / Double(threshold))
            }
        }

        let incoming = record.amount > 0
        var from: String?
        var to: String?
        if incoming {
            from = record.from.first(where: { $0.mine == false })?.address
        } else {
            to = record.to.first(where: { $0.mine == false })?.address
        }
        let sentToSelf = !record.from.contains(where: { !$0.mine }) && !record.to.contains(where: { !$0.mine })

        return TransactionViewItem(
                wallet: item.wallet,
                transactionHash: record.transactionHash,
                coinValue: CoinValue(coin: coin, value: record.amount),
                feeCoinValue: feeCoinValue,
                currencyValue: currencyValue,
                from: from,
                to: to,
                incoming: incoming,
                sentToSelf: sentToSelf,
                date: record.date,
                status: status,
                rate: rate
        )
    }

}
