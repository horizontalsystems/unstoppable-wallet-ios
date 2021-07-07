import Foundation
import EthereumKit
import CoinKit

class EvmTransactionRecord: TransactionRecord {
    typealias IncomingInternalETH = (from: String, value: CoinValue)
    typealias IncomingEip20Event = (from: String, value: CoinValue)
    typealias OutgoingEip20Event = (to: String, value: CoinValue)

    var incomingInternalETHs = [IncomingInternalETH]()
    var incomingEip20Events = [IncomingEip20Event]()
    var outgoingEip20Events = [OutgoingEip20Event]()
    let foreignTransaction: Bool
    let fee: CoinValue

    init(fullTransaction: FullTransaction, baseCoin: Coin, foreignTransaction: Bool = false) {
        let transaction = fullTransaction.transaction
        let receipt = fullTransaction.receiptWithLogs?.receipt
        let txHash = transaction.hash.toHexString()
        self.foreignTransaction = foreignTransaction

        let feeAmount: Int
        if let receipt = fullTransaction.receiptWithLogs?.receipt {
            feeAmount = receipt.gasUsed
        } else {
            feeAmount = fullTransaction.transaction.gasLimit
        }

        let feeDecimal = Decimal(sign: .plus, exponent: -EvmAdapter.decimal, significand: Decimal(feeAmount * transaction.gasPrice))
        fee = CoinValue(coin: baseCoin, value: feeDecimal)

        super.init(
                uid: txHash,
                transactionHash: txHash,
                transactionIndex: receipt?.transactionIndex ?? 0,
                blockHeight: receipt?.blockNumber,
                confirmationsThreshold: BaseEvmAdapter.confirmationsThreshold,
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                failed: fullTransaction.failed
        )
    }

}
