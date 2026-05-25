import EvmKit
import Foundation
import MarketKit
import WalletCore

class EvmOutgoingTransactionRecord: EvmTransactionRecord {
    let to: String
    let value: AppValue
    let sentToSelf: Bool

    init(source: WalletCore.TransactionSource, transaction: Transaction, baseToken: Token, to: String, value: AppValue, sentToSelf: Bool, protected: Bool) {
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true, protected: protected)
    }

    override var mainToken: MarketKit.Token? {
        value.token
    }

    override var mainValue: Decimal? {
        value.value
    }
}
