import Foundation
import MarketKit
import WalletCore

class MoneroIncomingTransactionRecord: MoneroTransactionRecord {
    let value: AppValue
    let from: String?
    let to: String?

    init(token: Token, source: TransactionSource, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: Decimal?, failed: Bool, amount: Decimal, from: String?, to: String? = nil, memo: String? = nil) {
        value = AppValue(token: token, value: amount)
        self.from = from
        self.to = to

        super.init(
            source: source,
            uid: uid,
            transactionHash: transactionHash,
            transactionIndex: transactionIndex,
            blockHeight: blockHeight,
            confirmationsThreshold: confirmationsThreshold,
            date: date,
            fee: fee.flatMap { AppValue(token: token, value: $0) },
            failed: failed,
            memo: memo
        )
    }

    override var mainToken: MarketKit.Token? {
        value.token
    }

    override var mainValue: Decimal? {
        value.value
    }
}
