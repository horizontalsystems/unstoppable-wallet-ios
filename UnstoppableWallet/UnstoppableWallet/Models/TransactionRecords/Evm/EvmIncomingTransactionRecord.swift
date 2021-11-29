import Foundation
import EthereumKit
import MarketKit

class EvmIncomingTransactionRecord: EvmTransactionRecord {
    let from: String
    let value: TransactionValue

    init(source: TransactionSource, fullTransaction: FullTransaction, baseCoin: PlatformCoin, from: String, value: TransactionValue, foreignTransaction: Bool = false) {
        self.from = from
        self.value = value

        super.init(source: source, fullTransaction: fullTransaction, baseCoin: baseCoin, foreignTransaction: foreignTransaction)
    }

    override var mainValue: TransactionValue? {
        value
    }

}
