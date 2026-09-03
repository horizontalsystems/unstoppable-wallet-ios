import EvmKit
import Foundation
import HsExtensions
import MarketKit
import WalletConnectSign

// Mirrors EvmSendHandler on the same primitives, but honors the dApp's gas limit and never adjusts the value
class WCNEvmSendHandler {
    private let payload: WCNEvmTransactionPayload
    private let request: WCNRequest
    private let evmKitWrapper: EvmKitWrapper
    private let responder: WCNResponder
    private let decorator = EvmDecorator()
    private let evmFeeEstimator = EvmFeeEstimator()

    init(payload: WCNEvmTransactionPayload, request: WCNRequest, evmKitWrapper: EvmKitWrapper, responder: WCNResponder) {
        self.payload = payload
        self.request = request
        self.evmKitWrapper = evmKitWrapper
        self.responder = responder
    }
}

extension WCNEvmSendHandler: ISendHandler {
    var baseToken: Token { payload.baseToken }

    var initialTransactionSettings: InitialTransactionSettings? {
        .evm(gasPrice: payload.transaction.initialGasPrice, nonce: payload.transaction.nonce)
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let transactionData = payload.transaction.transactionData
        let gasPriceData = transactionSettings?.gasPriceData
        var evmFeeData: EvmFeeData?
        var transactionError: Error?

        if let gasPriceData {
            if let gasLimit = payload.transaction.gasLimit {
                evmFeeData = EvmFeeData(gasLimit: gasLimit, surchargedGasLimit: gasLimit)
            } else {
                do {
                    evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPriceData: gasPriceData)
                } catch {
                    transactionError = error
                }
            }
        }

        let transactionDecoration = evmKitWrapper.evmKit.decorate(transactionData: transactionData)
        let decoration = decorator.decorate(baseToken: baseToken, transactionData: transactionData, transactionDecoration: transactionDecoration)

        let inner = EvmSendData(
            decoration: decoration,
            transactionData: transactionData,
            transactionError: transactionError,
            gasPrice: gasPriceData?.userDefined,
            evmFeeData: evmFeeData,
            nonce: transactionSettings?.nonce
        )

        return WCNSendData(inner: inner, request: request)
    }

    func send(data: ISendData) async throws {
        guard let data = (data as? WCNSendData)?.inner as? EvmSendData else {
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

        if payload.isSignOnly {
            guard let signer = evmKitWrapper.signer else {
                throw SendError.noSigner
            }
            guard let nonce = data.nonce ?? payload.transaction.nonce else {
                throw SendError.noNonce
            }

            let signedTransaction = try signer.signedTransaction(
                address: transactionData.to,
                value: transactionData.value,
                transactionInput: transactionData.input,
                gasPrice: gasPrice,
                gasLimit: gasLimit,
                nonce: nonce
            )
            try await responder.respond(request: payload, result: AnyCodable(signedTransaction.hs.hexString))
        } else {
            let fullTransaction = try await evmKitWrapper.send(
                transactionData: transactionData,
                gasPrice: gasPrice,
                gasLimit: gasLimit,
                privateSend: false,
                nonce: data.nonce
            )
            try await responder.respond(request: payload, result: AnyCodable(fullTransaction.transaction.hash.hs.hexString))
        }
    }
}

extension WCNEvmSendHandler {
    enum SendError: Error {
        case invalidData
        case noTransactionData
        case noGasPrice
        case noGasLimit
        case noSigner
        case noNonce
    }
}
