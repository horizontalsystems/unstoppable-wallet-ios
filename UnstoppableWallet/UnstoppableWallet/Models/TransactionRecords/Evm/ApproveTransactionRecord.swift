import Foundation
import EthereumKit
import MarketKit

class ApproveTransactionRecord: EvmTransactionRecord {
    let spender: String
    let value: TransactionValue

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin, spender: String, value: TransactionValue) {
        self.spender = spender
        self.value = value

        super.init(source: source, transaction: transaction, baseCoin: baseCoin)
    }

    override var mainValue: TransactionValue? {
        value
    }

}
