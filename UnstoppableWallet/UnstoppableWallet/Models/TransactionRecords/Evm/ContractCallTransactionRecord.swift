import Foundation
import EthereumKit
import MarketKit

class ContractCallTransactionRecord: EvmTransactionRecord {
    let contractAddress: String
    let method: String?
    let incomingEvents: [TransferEvent]
    let outgoingEvents: [TransferEvent]

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin,
         contractAddress: String, method: String?, incomingEvents: [TransferEvent], outgoingEvents: [TransferEvent]) {
        self.contractAddress = contractAddress
        self.method = method
        self.incomingEvents = incomingEvents
        self.outgoingEvents = outgoingEvents

        super.init(source: source, transaction: transaction, baseCoin: baseCoin, ownTransaction: true)
    }

    override var mainValue: TransactionValue? {
        if incomingEvents.count == 1, outgoingEvents.isEmpty {
            return incomingEvents[0].value
        } else if incomingEvents.isEmpty, outgoingEvents.count == 1 {
            return outgoingEvents[0].value
        } else {
            return nil
        }
    }

}
