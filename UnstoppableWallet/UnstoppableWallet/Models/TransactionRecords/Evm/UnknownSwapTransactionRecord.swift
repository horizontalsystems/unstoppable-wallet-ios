import Foundation
import EthereumKit
import MarketKit

class UnknownSwapTransactionRecord: EvmTransactionRecord {
    let exchangeAddress: String
    let valueIn: TransactionValue?
    let valueOut: TransactionValue?

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin, exchangeAddress: String, valueIn: TransactionValue?, valueOut: TransactionValue?) {
        self.exchangeAddress = exchangeAddress
        self.valueIn = valueIn
        self.valueOut = valueOut

        super.init(source: source, transaction: transaction, baseCoin: baseCoin, ownTransaction: true)
    }

}
