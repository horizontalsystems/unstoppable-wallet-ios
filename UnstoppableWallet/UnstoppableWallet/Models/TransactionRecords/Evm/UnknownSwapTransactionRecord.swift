import Foundation
import EthereumKit
import MarketKit

class UnknownSwapTransactionRecord: EvmTransactionRecord {
    let exchangeAddress: String
    let value: TransactionValue
    let internalTransactionEvents: [TransferEvent]
    let incomingEip20Events: [TransferEvent]
    let outgoingEip20Events: [TransferEvent]

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin, exchangeAddress: String,
         value: TransactionValue, internalTransactionEvents: [TransferEvent], incomingEip20Events: [TransferEvent], outgoingEip20Events: [TransferEvent]) {
        self.exchangeAddress = exchangeAddress
        self.value = value
        self.internalTransactionEvents = internalTransactionEvents
        self.incomingEip20Events = incomingEip20Events
        self.outgoingEip20Events = outgoingEip20Events

        super.init(source: source, transaction: transaction, baseCoin: baseCoin)
    }

}
