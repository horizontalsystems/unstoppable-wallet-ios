import EvmKit
import Foundation
import MarketKit

public class EvmOutgoingTransactionRecord: EvmTransactionRecord {
    public let to: String
    public let value: AppValue
    public let sentToSelf: Bool

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, to: String, value: AppValue, sentToSelf: Bool, protected: Bool) {
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true, protected: protected)
    }

    override public var mainValue: AppValue? {
        value
    }
}
