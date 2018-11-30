import Foundation

class TransactionViewItemFactory {
    private let latestRateFallbackThreshold: Double = 60 // in minutes

    private let walletManager: IWalletManager
    private let currencyManager: ICurrencyManager
    private let rateManager: IRateManager

    init(walletManager: IWalletManager, currencyManager: ICurrencyManager, rateManager: IRateManager) {
        self.walletManager = walletManager
        self.currencyManager = currencyManager
        self.rateManager = rateManager
    }
}

extension TransactionViewItemFactory: ITransactionViewItemFactory {

    func item(fromRecord record: TransactionRecord) -> TransactionViewItem {
        let adapter = walletManager.wallets.first(where: { $0.coin == record.coin })?.adapter

        var rateValue: Double?

        if record.rate == 0 {
            if record.timestamp > Date().timeIntervalSince1970 - 60 * latestRateFallbackThreshold, let rate = rateManager.rate(forCoin: record.coin, currencyCode: currencyManager.baseCurrency.code), !rate.expired {
                rateValue = rate.value
            }
        } else {
            rateValue = record.rate
        }

        let convertedValue = rateValue.map { $0 * record.amount }

        var status: TransactionStatus = .pending

        if record.blockHeight != 0, let adapter = adapter, let lastBlockHeight = adapter.lastBlockHeight {
            let confirmations = lastBlockHeight - record.blockHeight + 1
            let threshold = adapter.confirmationsThreshold

            if confirmations >= threshold {
                status = .completed
            } else {
                status = .processing(progress: Double(confirmations) / Double(threshold))
            }
        }

        let incoming = record.amount > 0

        return TransactionViewItem(
                transactionHash: record.transactionHash,
                coinValue: CoinValue(coin: record.coin, value: record.amount),
                currencyValue: convertedValue.map { CurrencyValue(currency: currencyManager.baseCurrency, value: $0) },
                from: record.from.first(where: { $0.mine != incoming })?.address,
                to: record.to.first(where: { $0.mine == incoming })?.address,
                incoming: incoming,
                date: record.timestamp == 0 ? nil : Date(timeIntervalSince1970: Double(record.timestamp)),
                status: status
        )
    }

}
