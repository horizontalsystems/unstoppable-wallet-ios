import Foundation
import EthereumKit
import MarketKit

class ContractCallTransactionRecord: EvmTransactionRecord {
    let contractAddress: String?
    let method: String?
    let value: TransactionValue?
    let internalTransactionEvents: [TransferEvent]
    let incomingEip20Events: [TransferEvent]
    let outgoingEip20Events: [TransferEvent]

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin,
         contractAddress: String?, method: String?, value: TransactionValue?, internalTransactionEvents: [TransferEvent], incomingEip20Events: [TransferEvent], outgoingEip20Events: [TransferEvent],
         foreignTransaction: Bool = false) {
        self.contractAddress = contractAddress
        self.method = method
        self.value = value
        self.internalTransactionEvents = internalTransactionEvents
        self.incomingEip20Events = incomingEip20Events
        self.outgoingEip20Events = outgoingEip20Events

        super.init(source: source, transaction: transaction, baseCoin: baseCoin, foreignTransaction: foreignTransaction)
    }

}
