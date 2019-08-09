import Foundation

class TransactionViewItemFactory: ITransactionViewItemFactory {

    func viewItem(fromItem item: TransactionItem, lastBlockHeight: Int? = nil, threshold: Int? = nil, rate: CurrencyValue? = nil) -> TransactionViewItem {
        let record = item.record

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

        return TransactionViewItem(
                wallet: item.wallet,
                transactionHash: record.transactionHash,
                coinValue: CoinValue(coinCode: item.wallet.coin.code, value: record.amount),
                currencyValue: currencyValue,
                from: from,
                to: to,
                incoming: incoming,
                date: record.date,
                status: status,
                rate: rate
        )
    }

}
