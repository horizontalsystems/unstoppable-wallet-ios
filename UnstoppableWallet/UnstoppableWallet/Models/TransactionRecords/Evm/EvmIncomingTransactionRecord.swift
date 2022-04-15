import Foundation
import EthereumKit
import MarketKit

class EvmIncomingTransactionRecord: EvmTransactionRecord {
    let from: String
    let value: TransactionValue

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin, from: String, value: TransactionValue) {
        self.from = from
        self.value = value

        super.init(source: source, transaction: transaction, baseCoin: baseCoin, ownTransaction: false)
    }

    override var mainValue: TransactionValue? {
        value
    }

}
