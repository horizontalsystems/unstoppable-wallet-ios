import BigInt
import EvmKit
import Foundation
import MarketKit

class EvmResendHandler: SendHandler {
    let baseToken: Token
    private let evmKitWrapper: EvmKitWrapper
    private let transaction: EvmKit.Transaction
    private let type: ResendTransactionType
    private let decorator = EvmDecorator()
    private let feeEstimator = EvmFeeEstimator()

    init(baseToken: Token, evmKitWrapper: EvmKitWrapper, transaction: EvmKit.Transaction, type: ResendTransactionType) {
        self.baseToken = baseToken
        self.evmKitWrapper = evmKitWrapper
        self.transaction = transaction
        self.type = type
    }

    override class func instance(sendData: SendData) -> ISendHandler? {
        guard case let .evmResend(blockchainType, transaction, type) = sendData,
              let baseToken = try? Core.shared.coinManager.token(query: .init(blockchainType: blockchainType, tokenType: .native)),
              let wrapper = try? Core.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper,
              transaction.from == wrapper.evmKit.receiveAddress
        else { return nil }

        let handler = EvmResendHandler(baseToken: baseToken, evmKitWrapper: wrapper, transaction: transaction, type: type)
        guard (try? handler.replacementData()) != nil else { return nil }
        return handler
    }

    private func replacementData() throws -> EvmReplacementData {
        guard let fullTransaction = evmKitWrapper.evmKit.transaction(hash: transaction.hash),
              fullTransaction.transaction.nonce == transaction.nonce
        else {
            throw EvmReplacementData.ValidationError.wrongTransaction
        }

        return try Self.prepare(
            transaction: fullTransaction.transaction,
            blockchainType: evmKitWrapper.blockchainType,
            receiveAddress: evmKitWrapper.evmKit.receiveAddress,
            isProtected: MerkleTransactionAdapter.isProtected(transaction: fullTransaction),
            type: type
        )
    }

    static func prepare(transaction: EvmKit.Transaction, blockchainType: BlockchainType, receiveAddress: EvmKit.Address, isProtected: Bool, type: ResendTransactionType) throws -> EvmReplacementData {
        let replacementData = try EvmReplacementData(transaction: transaction, receiveAddress: receiveAddress, type: type)

        guard transaction.replacedWith == nil else {
            throw ValidationError.alreadyReplaced
        }

        guard transaction.from == receiveAddress, transaction.nonce != nil else {
            throw EvmReplacementData.ValidationError.wrongTransaction
        }

        guard blockchainType.resendable, !isProtected, !transaction.isFailed else {
            throw ValidationError.notAllowed
        }

        return replacementData
    }
}

extension EvmResendHandler: ISendHandler {
    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let replacement = try replacementData()
        let transactionData = replacement.transactionData
        let gasPriceData = transactionSettings?.gasPriceData
        var feeData: EvmFeeData?
        var transactionError: Error?

        if let gasPriceData {
            do {
                if let gasLimit = replacement.predefinedGasLimit {
                    feeData = EvmFeeData(gasLimit: gasLimit, surchargedGasLimit: gasLimit)
                } else {
                    feeData = try await feeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPriceData: gasPriceData)
                }

                if let feeData, transactionData.value + feeData.totalFee(gasPrice: gasPriceData.userDefined) > (evmKitWrapper.evmKit.accountState?.balance ?? 0) {
                    throw AppError.ethereum(reason: .insufficientBalanceWithFee)
                }
            } catch {
                transactionError = error
            }
        }

        let transactionDecoration = evmKitWrapper.evmKit.decorate(transactionData: transactionData)
        let decoration = decorator.decorate(baseToken: baseToken, transactionData: transactionData, transactionDecoration: transactionDecoration)

        let swap = EvmResendSwapData(decoration: transactionDecoration, baseToken: baseToken) { address in
            try? Core.shared.coinManager.token(query: .init(blockchainType: self.baseToken.blockchainType, tokenType: .eip20(address: address.hex)))
        }

        return EvmResendData(
            decoration: decoration,
            swap: swap,
            transactionData: transactionData,
            transactionError: transactionError,
            gasPrice: gasPriceData?.userDefined,
            evmFeeData: feeData,
            nonce: transaction.nonce
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? EvmSendData, data.canSend, data.nonce == transaction.nonce,
              let transactionData = data.transactionData,
              let gasPrice = data.gasPrice,
              let gasLimit = data.evmFeeData?.surchargedGasLimit
        else {
            throw EvmSendHandler.SendError.invalidData
        }

        _ = try replacementData()
        _ = try await evmKitWrapper.send(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit, privateSend: false, nonce: transaction.nonce)
    }
}

extension EvmResendHandler {
    enum ValidationError: LocalizedError {
        case alreadyReplaced
        case notAllowed

        var errorDescription: String? {
            switch self {
            case .alreadyReplaced: return "alert.already_replaced".localized
            case .notAllowed: return "alert.unknown_error".localized
            }
        }
    }
}
