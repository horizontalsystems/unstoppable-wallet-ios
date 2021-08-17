import Foundation
import EthereumKit
import CoinKit

class EvmTransactionRecord: TransactionRecord {
    let foreignTransaction: Bool
    let fee: CoinValue

    init(source: TransactionSource, fullTransaction: FullTransaction, baseCoin: Coin, foreignTransaction: Bool = false) {
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
                source: source,
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
