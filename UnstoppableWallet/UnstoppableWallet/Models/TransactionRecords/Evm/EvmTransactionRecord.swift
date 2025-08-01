import EvmKit
import Foundation
import MarketKit

class EvmTransactionRecord: TransactionRecord {
    let transaction: Transaction
    let ownTransaction: Bool
    let protected: Bool
    let fee: AppValue?

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, ownTransaction: Bool, protected: Bool, spam: Bool = false) {
        self.transaction = transaction
        let txHash = transaction.hash.hs.hexString
        self.ownTransaction = ownTransaction
        self.protected = protected

        if let feeAmount = transaction.gasUsed ?? transaction.gasLimit, let gasPrice = transaction.gasPrice {
            let feeDecimal = Decimal(sign: .plus, exponent: -baseToken.decimals, significand: Decimal(feeAmount) * Decimal(gasPrice))
            fee = AppValue(token: baseToken, value: feeDecimal)
        } else {
            fee = nil
        }

        super.init(
            source: source,
            uid: txHash,
            transactionHash: txHash,
            transactionIndex: transaction.transactionIndex ?? 0,
            blockHeight: transaction.blockNumber,
            confirmationsThreshold: BaseEvmAdapter.confirmationsThreshold,
            date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
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
}
