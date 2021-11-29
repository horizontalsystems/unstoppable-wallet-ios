import Foundation
import EthereumKit
import MarketKit

class ApproveTransactionRecord: EvmTransactionRecord {
    let spender: String
    let value: TransactionValue

    init(source: TransactionSource, fullTransaction: FullTransaction, baseCoin: PlatformCoin, spender: String, value: TransactionValue) {
        self.spender = spender
        self.value = value

        super.init(source: source, fullTransaction: fullTransaction, baseCoin: baseCoin)
    }

    override var mainValue: TransactionValue? {
        value
    }

}
