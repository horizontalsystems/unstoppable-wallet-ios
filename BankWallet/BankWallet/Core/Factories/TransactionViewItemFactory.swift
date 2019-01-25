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

        return TransactionViewItem(
                transactionHash: record.transactionHash,
                coinValue: CoinValue(coinCode: item.coinCode, value: record.amount),
                currencyValue: currencyValue,
                from: record.from.first(where: { $0.mine != incoming })?.address,
                to: record.to.first(where: { $0.mine == incoming })?.address,
                incoming: incoming,
                date: Date(timeIntervalSince1970: record.timestamp),
                status: status
        )
    }

}
