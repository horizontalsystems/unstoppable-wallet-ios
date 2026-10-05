import EvmKit
import Foundation

struct EvmReplacementData {
    let transactionData: TransactionData
    let predefinedGasLimit: Int?

    init(transaction: EvmKit.Transaction, receiveAddress: EvmKit.Address, type: ResendTransactionType) throws {
        guard let value = transaction.value, let input = transaction.input, let to = transaction.to else {
            throw ValidationError.wrongTransaction
        }

        guard transaction.blockNumber == nil else {
            throw ValidationError.alreadyInBlock
        }

        switch type {
        case .speedUp:
            transactionData = TransactionData(to: to, value: value, input: input)
            predefinedGasLimit = transaction.gasLimit
        case .cancel:
            transactionData = TransactionData(to: receiveAddress, value: 0, input: Data())
            predefinedGasLimit = nil
        }
    }
}

extension EvmReplacementData {
    enum ValidationError: LocalizedError {
        case wrongTransaction
        case alreadyInBlock

        var errorDescription: String? {
            switch self {
            case .wrongTransaction: return "alert.unknown_error".localized
            case .alreadyInBlock: return "tx_info.transaction.already_in_block".localized
            }
        }
    }
}
