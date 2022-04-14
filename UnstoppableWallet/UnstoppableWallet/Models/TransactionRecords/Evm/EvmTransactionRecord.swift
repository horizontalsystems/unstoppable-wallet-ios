import Foundation
import EthereumKit
import MarketKit

class EvmTransactionRecord: TransactionRecord {
    let transaction: Transaction
    let foreignTransaction: Bool
    let fee: TransactionValue?

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin, foreignTransaction: Bool = false) {
        self.transaction = transaction
        let txHash = transaction.hash.toHexString()
        self.foreignTransaction = foreignTransaction

        if let feeAmount = transaction.gasUsed ?? transaction.gasLimit, let gasPrice = transaction.gasPrice {
            let feeDecimal = Decimal(sign: .plus, exponent: -baseCoin.decimals, significand: Decimal(feeAmount) * Decimal(gasPrice))
            fee = .coinValue(platformCoin: baseCoin, value: feeDecimal)
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
                failed: transaction.isFailed
        )
    }

}

extension EvmTransactionRecord {

    struct TransferEvent {
        let address: String
        let value: TransactionValue
    }

}
