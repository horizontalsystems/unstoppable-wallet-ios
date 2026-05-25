import EvmKit
import Foundation
import MarketKit
import WalletCore

class ExternalContractCallTransactionRecord: EvmTransactionRecord, TransferEventsProvider {
    let incomingEvents: [TransferEvent]
    let outgoingEvents: [TransferEvent]

    init(source: WalletCore.TransactionSource, transaction: Transaction, baseToken: Token, incomingEvents: [TransferEvent], outgoingEvents: [TransferEvent], spam: Bool = false, protected: Bool) {
        self.incomingEvents = incomingEvents
        self.outgoingEvents = outgoingEvents

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: false, protected: protected, spam: spam)
    }

    var combinedValues: ([AppValue], [AppValue]) {
        combined(incomingEvents: incomingEvents, outgoingEvents: outgoingEvents)
    }

    private var mainAppValue: AppValue? {
        let (incomingValues, outgoingValues) = combinedValues

        if incomingValues.count == 1, outgoingValues.isEmpty {
            return incomingValues[0]
        } else if incomingValues.isEmpty, outgoingValues.count == 1 {
            return outgoingValues[0]
        } else {
            return nil
        }
    }

    override var mainToken: MarketKit.Token? {
        mainAppValue?.token
    }

    override var mainValue: Decimal? {
        mainAppValue?.value
    }

    var transferEvents: TransferEvents {
        .init(incoming: incomingEvents, outgoing: outgoingEvents)
    }
}
