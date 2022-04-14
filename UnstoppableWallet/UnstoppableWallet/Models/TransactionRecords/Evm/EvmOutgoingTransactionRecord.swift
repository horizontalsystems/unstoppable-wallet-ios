import Foundation
import EthereumKit
import MarketKit

class EvmOutgoingTransactionRecord: EvmTransactionRecord {
    let to: String
    let value: TransactionValue
    let sentToSelf: Bool

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin, to: String, value: TransactionValue, sentToSelf: Bool) {
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, baseCoin: baseCoin)
    }

    override var mainValue: TransactionValue? {
        value
    }

}
