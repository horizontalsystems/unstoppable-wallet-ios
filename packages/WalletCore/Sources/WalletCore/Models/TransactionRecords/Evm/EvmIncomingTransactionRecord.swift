import EvmKit
import Foundation
import MarketKit

public class EvmIncomingTransactionRecord: EvmTransactionRecord, TransferEventsProvider {
    public let from: String
    public let value: AppValue

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, from: String, value: AppValue, spam: Bool = false) {
        self.from = from
        self.value = value

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: false, protected: false, spam: spam)
    }

    override public var mainValue: AppValue? {
        value
    }

    public var transferEvents: TransferEvents {
        .init(incoming: [.init(address: from, value: value)])
    }
}
