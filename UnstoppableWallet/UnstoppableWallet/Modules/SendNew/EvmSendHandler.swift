import EvmKit
import Foundation
import MarketKit

class EvmSendHandler {
    let baseToken: Token
    private let transactionData: TransactionData
    private let evmKitWrapper: EvmKitWrapper
    private let decorator = EvmDecorator()
    private let evmFeeEstimator = EvmFeeEstimator()

    init(baseToken: Token, transactionData: TransactionData, evmKitWrapper: EvmKitWrapper) {
        self.baseToken = baseToken
        self.transactionData = transactionData
        self.evmKitWrapper = evmKitWrapper
    }
}

extension EvmSendHandler: ISendHandler {
    var expirationDuration: Int? {
        10
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let gasPrice = transactionSettings?.gasPrice
        var evmFeeData: EvmFeeData?
        var transactionError: Error?

        var transactionData = transactionData

        if let gasPrice {
            let evmBalance = evmKitWrapper.evmKit.accountState?.balance ?? 0

            do {
                if transactionData.input.isEmpty, transactionData.value == evmBalance {
                    let stubTransactionData = TransactionData(to: transactionData.to, value: 1, input: transactionData.input)
                    let stubFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: stubTransactionData, gasPrice: gasPrice)
                    let totalFee = stubFeeData.totalFee(gasPrice: gasPrice)

                    evmFeeData = stubFeeData
                    transactionData = TransactionData(to: transactionData.to, value: max(0, transactionData.value - totalFee), input: transactionData.input)
                } else {
                    evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPrice: gasPrice)
                }
            } catch {
                transactionError = error
            }
        }

        let transactionDecoration = evmKitWrapper.evmKit.decorate(transactionData: transactionData)
        let decoration = decorator.decorate(baseToken: baseToken, transactionData: transactionData, transactionDecoration: transactionDecoration)

        return EvmSendData(
            decoration: decoration,
            transactionData: transactionData,
            transactionError: transactionError,
            gasPrice: gasPrice,
            evmFeeData: evmFeeData,
            nonce: transactionSettings?.nonce
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? EvmSendData else {
            throw SendError.invalidData
        }

        guard let transactionData = data.transactionData else {
            throw SendError.noTransactionData
        }

        guard let gasPrice = data.gasPrice else {
            throw SendError.noGasPrice
        }

        guard let gasLimit = data.evmFeeData?.surchargedGasLimit else {
            throw SendError.noGasLimit
        }

        _ = try await evmKitWrapper.send(
            transactionData: transactionData,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            nonce: data.nonce
        )
    }
}

extension EvmSendHandler {
    enum SendError: Error {
        case invalidData
        case noGasPrice
        case noGasLimit
        case noTransactionData
    }
}

extension EvmSendHandler {
    static func instance(blockchainType: BlockchainType, transactionData: TransactionData) -> EvmSendHandler? {
        guard let baseToken = try? App.shared.coinManager.token(query: .init(blockchainType: blockchainType, tokenType: .native)) else {
            return nil
        }

        guard let evmKitWrapper = App.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper else {
            return nil
        }

        return EvmSendHandler(
            baseToken: baseToken,
            transactionData: transactionData,
            evmKitWrapper: evmKitWrapper
        )
    }
}
