import Foundation
import EthereumKit

class EvmTransactionRecord: TransactionRecord {
    typealias IncomingInternalETH = (from: String, amount: Decimal)
    typealias IncomingEip20Event = (from: String, amount: Decimal)
    typealias OutgoingEip20Event = (to: String, amount: Decimal)

    var incomingInternalETHs = [IncomingInternalETH]()
    var incomingEip20Events = [IncomingEip20Event]()
    var outgoingEip20Events = [OutgoingEip20Event]()

    init(fullTransaction: FullTransaction) {
        let transaction = fullTransaction.transaction
        let receipt = fullTransaction.receiptWithLogs?.receipt
        let txHash = transaction.hash.toHexString()

        super.init(
                uid: txHash,
                transactionHash: txHash,
                transactionIndex: receipt?.transactionIndex ?? 0,
                blockHeight: receipt?.blockNumber,
                confirmationsThreshold: BaseEvmAdapter.confirmationsThreshold,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                fee: receipt.map { Decimal(sign: .plus, exponent: -EvmAdapter.decimal, significand: Decimal($0.gasUsed * transaction.gasPrice)) },
                failed: fullTransaction.failed
        )
    }

}
