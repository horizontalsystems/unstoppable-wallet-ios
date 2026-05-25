import Foundation
import MarketKit
import TronKit
import WalletCore

class TronOutgoingTransactionRecord: TronTransactionRecord {
    let to: String
    let value: AppValue
    let sentToSelf: Bool

    init(source: WalletCore.TransactionSource, transaction: Transaction, baseToken: Token, to: String, value: AppValue, sentToSelf: Bool) {
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: true)
    }

    override var mainToken: MarketKit.Token? {
        value.token
    }

    override var mainValue: Decimal? {
        value.value
    }
}
