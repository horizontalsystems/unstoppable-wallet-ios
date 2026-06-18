import EvmKit
import Foundation
import MarketKit

public class ExternalContractCallTransactionRecord: EvmTransactionRecord, TransferEventsProvider {
    public let incomingEvents: [TransferEvent]
    public let outgoingEvents: [TransferEvent]

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, incomingEvents: [TransferEvent], outgoingEvents: [TransferEvent], spam: Bool = false, protected: Bool) {
        self.incomingEvents = incomingEvents
        self.outgoingEvents = outgoingEvents

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: false, protected: protected, spam: spam)
    }

    public var combinedValues: ([AppValue], [AppValue]) {
        combined(incomingEvents: incomingEvents, outgoingEvents: outgoingEvents)
    }

    override public var mainValue: AppValue? {
        let (incomingValues, outgoingValues) = combinedValues

        if incomingValues.count == 1, outgoingValues.isEmpty {
            return incomingValues[0]
        } else if incomingValues.isEmpty, outgoingValues.count == 1 {
            return outgoingValues[0]
        } else {
            return nil
        }
    }

    public var transferEvents: TransferEvents {
        .init(incoming: incomingEvents, outgoing: outgoingEvents)
    }
}
