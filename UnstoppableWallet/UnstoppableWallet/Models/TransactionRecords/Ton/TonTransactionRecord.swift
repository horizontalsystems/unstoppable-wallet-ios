import Foundation
import MarketKit
import TonKit

class TonTransactionRecord: TransactionRecord {
    let fee: TransactionValue?
    let lt: Int64
    let memo: String?

    init(source: TransactionSource, event: AccountEvent, feeToken: Token) {
        fee = .coinValue(token: feeToken, value: TonAdapter.amount(kitAmount: Decimal(event.fee)))
        lt = event.lt
        memo = event.actions.compactMap { ($0 as? TonTransfer)?.comment }.first

        super.init(
            source: source,
            uid: event.eventId,
            transactionHash: event.eventId,
            transactionIndex: 0,
            blockHeight: nil,
            confirmationsThreshold: nil,
            date: Date(timeIntervalSince1970: TimeInterval(event.timestamp)),
            failed: false
        )
    }

    override func status(lastBlockHeight _: Int?) -> TransactionStatus {
        .completed
    }
}

extension TonTransactionRecord {
    struct Transfer {
        let address: String
        let value: TransactionValue
    }
}
