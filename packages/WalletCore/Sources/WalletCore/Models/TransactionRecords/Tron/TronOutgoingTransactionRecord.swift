import Foundation
import MarketKit
import TronKit

public class TronOutgoingTransactionRecord: TronTransactionRecord {
    public let to: String
    public let value: AppValue
    public let sentToSelf: Bool

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, to: String, value: AppValue, sentToSelf: Bool) {
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

    override public var mainValue: AppValue? {
        value
    }
}
