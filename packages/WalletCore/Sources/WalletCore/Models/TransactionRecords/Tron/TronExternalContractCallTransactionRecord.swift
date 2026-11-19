import Foundation
import MarketKit
import TronKit

public class TronExternalContractCallTransactionRecord: TronTransactionRecord, TransferEventsProvider {
    public let incomingEvents: [TransferEvent]
    public let outgoingEvents: [TransferEvent]
    // the call's input, for overlays that read what was called
    public let data: Data?

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, incomingEvents: [TransferEvent], outgoingEvents: [TransferEvent], data: Data? = nil, spam: Bool = false) {
        self.incomingEvents = incomingEvents
        self.outgoingEvents = outgoingEvents
        self.data = data

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: false, spam: spam)
    }

    var combinedValues: ([AppValue], [AppValue]) {
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

    var transferEvents: TransferEvents {
        .init(incoming: incomingEvents, outgoing: outgoingEvents)
    }
}
