import Foundation
import MarketKit
import TronKit

class TronTransactionRecord: TransactionRecord {
    let transaction: Transaction
    let confirmed: Bool
    let ownTransaction: Bool
    let fee: AppValue?

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, ownTransaction: Bool, spam: Bool = false) {
        self.transaction = transaction
        confirmed = transaction.confirmed
        let txHash = transaction.hash.hs.hex
        self.ownTransaction = ownTransaction

        if let feeAmount = transaction.fee {
            let feeDecimal = Decimal(sign: .plus, exponent: -baseToken.decimals, significand: Decimal(feeAmount))
            fee = AppValue(token: baseToken, value: feeDecimal)
        } else {
            fee = nil
        }

        super.init(
            source: source,
            uid: txHash,
            transactionHash: txHash,
            transactionIndex: 0,
            blockHeight: transaction.blockNumber,
            confirmationsThreshold: BaseTronAdapter.confirmationsThreshold,
            date: Date(timeIntervalSince1970: Double(transaction.timestamp / 1000)),
            failed: transaction.isFailed,
            spam: spam
        )
    }

    func combined(incomingEvents: [TransferEvent], outgoingEvents: [TransferEvent]) -> ([AppValue], [AppValue]) {
        let values = (incomingEvents + outgoingEvents).map(\.value)
        var resultIncoming = [AppValue]()
        var resultOutgoing = [AppValue]()

        for value in values {
            if (resultIncoming + resultOutgoing).contains(where: { value.kind == $0.kind }) {
                continue
            }

            let sameTypeValues = values.filter { value.kind == $0.kind }
            let totalValue = sameTypeValues.map(\.value).reduce(0, +)
            let resultValue = AppValue(kind: value.kind, value: totalValue)

            if totalValue > 0 {
                resultIncoming.append(resultValue)
            } else {
                resultOutgoing.append(resultValue)
            }
        }

        return (resultIncoming, resultOutgoing)
    }

    override func status(lastBlockHeight _: Int?) -> TransactionStatus {
        if failed {
            return .failed
        }

        if confirmed {
            return .completed
        }

        return .pending
    }
}

extension TronTransactionRecord {
    struct TransferEvent {
        let address: String
        let value: AppValue
    }
}
