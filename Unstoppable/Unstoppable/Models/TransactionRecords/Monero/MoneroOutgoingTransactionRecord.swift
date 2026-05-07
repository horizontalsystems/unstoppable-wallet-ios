import Foundation
import MarketKit

class MoneroOutgoingTransactionRecord: MoneroTransactionRecord {
    let value: AppValue
    let to: String?
    let sentToSelf: Bool
    let txSecretKey: String?

    init(token: Token, source: TransactionSource, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, fee: Decimal?, failed: Bool, amount: Decimal, to: String?, sentToSelf: Bool, memo: String? = nil, txSecretKey: String? = nil) {
        value = AppValue(token: token, value: Decimal(sign: .minus, exponent: amount.exponent, significand: amount.significand))
        self.to = to
        self.sentToSelf = sentToSelf
        self.txSecretKey = txSecretKey

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

    override var mainValue: AppValue? {
        value
    }
}
