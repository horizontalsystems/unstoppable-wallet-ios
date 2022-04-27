import Foundation
import EthereumKit
import MarketKit

class ExternalContractCallTransactionRecord: EvmTransactionRecord {
    let incomingEvents: [TransferEvent]
    let outgoingEvents: [TransferEvent]

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin, incomingEvents: [TransferEvent], outgoingEvents: [TransferEvent]) {
        self.incomingEvents = incomingEvents
        self.outgoingEvents = outgoingEvents

        super.init(source: source, transaction: transaction, baseCoin: baseCoin, ownTransaction: false)
    }

    var combinedValues: ([TransactionValue], [TransactionValue]) {
        combined(incomingEvents: incomingEvents, outgoingEvents: outgoingEvents)
    }

    override var mainValue: TransactionValue? {
        let (incomingValues, outgoingValues) = combinedValues

        if incomingValues.count == 1, outgoingValues.isEmpty {
            return incomingValues[0]
        } else if incomingValues.isEmpty, outgoingValues.count == 1 {
            return outgoingValues[0]
        } else {
            return nil
        }
    }

}
