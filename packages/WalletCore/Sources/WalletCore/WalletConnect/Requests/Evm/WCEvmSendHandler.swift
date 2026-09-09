import EvmKit
import Foundation
import HsExtensions
import MarketKit
import WalletConnectSign

// Mirrors EvmSendHandler on the same primitives, but honors the dApp's gas limit and never adjusts the value
class WCEvmSendHandler {
    private let payload: WCEvmTransactionPayload
    private let request: WCRequest
    private let evmKitWrapper: EvmKitWrapper
    private let responder: WCResponder
    private let accountName: String?
    private let decorator = EvmDecorator()
    private let evmFeeEstimator = EvmFeeEstimator()

    init(payload: WCEvmTransactionPayload, request: WCRequest, evmKitWrapper: EvmKitWrapper, responder: WCResponder, accountName: String?) {
        self.payload = payload
        self.request = request
        self.evmKitWrapper = evmKitWrapper
        self.responder = responder
        self.accountName = accountName
    }
}

extension WCEvmSendHandler: ISendHandler {
    var baseToken: Token { payload.baseToken }

    var initialTransactionSettings: InitialTransactionSettings? {
        .evm(gasPrice: payload.transaction.initialGasPrice, nonce: payload.transaction.nonce)
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        // Prefer the service gas price once it arrives, but fall back to the dApp's own gas price so the
        // fee renders without waiting for the service's recommended gas price (Android parity).
        let gasPrice = transactionSettings?.gasPriceData?.userDefined ?? payload.transaction.initialGasPrice
        var evmFeeData: EvmFeeData?
        var transactionError: Error?

        if let gasPrice {
            if let gasLimit = payload.transaction.gasLimit {
                evmFeeData = EvmFeeData(gasLimit: gasLimit, surchargedGasLimit: gasLimit)
            } else {
                do {
                    let gasPriceData = transactionSettings?.gasPriceData ?? GasPriceData(recommended: gasPrice, userDefined: gasPrice)
                    evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: payload.transaction.transactionData, gasPriceData: gasPriceData)
                } catch {
                    transactionError = error
                }
            }
        }

        return makeSendData(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: transactionSettings?.nonce, transactionError: transactionError)
    }

    // The rows are decoded synchronously from the fixed dApp transaction; only the fee needs the network.
    // Shared by the async send path (fee estimated) and the sync preview (fee nil) so both render identically.
    private func makeSendData(gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?, transactionError: Error?) -> ISendData {
        let transactionData = payload.transaction.transactionData

        // Same guard as EvmSendHandler: once the fee is known, block signing when the wallet can't cover
        // value + fee. A dApp-fixed gas limit skips estimation, so this local check is the only place the
        // shortfall surfaces. Set as transactionError so EvmSendData renders the caution and disables send.
        var transactionError = transactionError
        // only assert insufficiency when the balance is actually known (accountState loaded); treating an
        // unknown balance as 0 would flash a false alert in the preview that clears after sync (and resizes
        // the fixed-size sheet)
        if transactionError == nil, let gasPrice, let evmFeeData, let evmBalance = evmKitWrapper.evmKit.accountState?.balance {
            if evmBalance < transactionData.value + evmFeeData.totalFee(gasPrice: gasPrice) {
                transactionError = AppError.ethereum(reason: .insufficientBalanceWithFee)
            }
        }

        let transactionDecoration = evmKitWrapper.evmKit.decorate(transactionData: transactionData)
        let decoration = decorator.decorate(baseToken: baseToken, transactionData: transactionData, transactionDecoration: transactionDecoration)

        let inner = EvmSendData(
            decoration: decoration,
            transactionData: transactionData,
            transactionError: transactionError,
            gasPrice: gasPrice,
            evmFeeData: evmFeeData,
            nonce: nonce
        )

        var header: WCSendHeader?
        if case .approveEip20 = decoration.type {
            header = WCSendHeader(title: "wallet_connect.allowance.title".localized, description: "wallet_connect.allowance.description".localized(request.dAppName))
        }
        return WCSendData(inner: WCEvmSendData(evmSendData: inner), request: request, header: header, accountName: accountName)
    }

    func send(data: ISendData) async throws {
        guard !request.isBlocked else { throw SendError.blocked }
        guard let data = ((data as? WCSendData)?.inner as? WCEvmSendData)?.evmSendData else {
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

extension WCEvmSendHandler: IWCPreviewSendHandler {
    func previewSendData() -> ISendData? {
        makeSendData(gasPrice: payload.transaction.initialGasPrice, evmFeeData: dAppFixedFeeData(), nonce: payload.transaction.nonce, transactionError: nil)
    }

    // The fee needs no network call only when the dApp fixed both gas price and gas limit; otherwise nil,
    // so the fee row stays pending (spinner) until sendData() estimates it.
    private func dAppFixedFeeData() -> EvmFeeData? {
        guard payload.transaction.initialGasPrice != nil, let gasLimit = payload.transaction.gasLimit else { return nil }
        return EvmFeeData(gasLimit: gasLimit, surchargedGasLimit: gasLimit)
    }
}

extension WCEvmSendHandler {
    enum SendError: Error {
        case blocked
        case invalidData
        case noTransactionData
        case noGasPrice
        case noGasLimit
        case noSigner
        case noNonce
    }
}
