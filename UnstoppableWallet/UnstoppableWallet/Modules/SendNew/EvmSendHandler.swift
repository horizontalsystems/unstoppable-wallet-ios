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
        let gasPriceData = transactionSettings?.gasPriceData
        var evmFeeData: EvmFeeData?
        var transactionError: Error?
        var transactionData = transactionData

        if let gasPriceData {
            let evmBalance = evmKitWrapper.evmKit.accountState?.balance ?? 0

            do {
                if transactionData.input.isEmpty, transactionData.value == evmBalance {
                    let stubTransactionData = TransactionData(to: transactionData.to, value: 1, input: transactionData.input)
                    let stubFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: stubTransactionData, gasPriceData: gasPriceData)
                    let totalFee = stubFeeData.totalFee(gasPrice: gasPriceData.userDefined)

                    evmFeeData = stubFeeData
                    let value = transactionData.value > totalFee ? transactionData.value - totalFee : 0
                    transactionData = TransactionData(to: transactionData.to, value: value, input: transactionData.input)

                    if transactionData.value == 0 {
                        throw AppError.ethereum(reason: .insufficientBalanceWithFee)
                    }
                } else {
                    let _evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPriceData: gasPriceData)
                    let totalFee = _evmFeeData.totalFee(gasPrice: gasPriceData.userDefined)

                    evmFeeData = _evmFeeData

                    if evmBalance < totalFee {
                        throw AppError.ethereum(reason: .insufficientBalanceWithFee)
                    }
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
            gasPrice: gasPriceData?.userDefined,
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
