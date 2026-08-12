import Foundation
import MarketKit
import stellarsdk

final class USwapStellarFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let adapterManager: AdapterManager

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType == .stellar
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: input.tokenIn) as? StellarAdapter else {
            throw USwapMultiSwapProvider.SwapError.noStellarAdapter
        }

        let asset = adapter.asset

        guard let execution = input.response.execution else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }

        if case .signedTransaction = execution {
            guard let xdr = execution.primarySignable?.xdr else {
                throw USwapMultiSwapProvider.SwapError.invalidTransactionData
            }

            let fee = (try? TransactionEnvelopeXDR(fromBase64: xdr)).map {
                Decimal($0.txFee) / 10_000_000
            }

            return StellarSwapFinalQuote(
                amountIn: input.amountIn,
                expectedAmountOut: input.response.expectedBuyAmount,
                recipient: input.recipient,
                slippage: input.slippage,
                estimatedTime: input.response.estimatedTime,
                transactionData: .envelope(xdr),
                token: input.tokenIn,
                fee: fee,
                transactionError: nil,
                toAddress: input.destinationAddress,
                providerSwapId: input.providerSwapId
            )
        }

        if case .stellarBroker = execution {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }

        guard let deposit = execution.depositInstruction() else {
            throw USwapMultiSwapProvider.SwapError.invalidTransactionData
        }

        // A text memo IS deliverable here and must keep working: a Stellar text memo is a plain,
        // publicly readable field of the payment transaction. Still throws on a destination tag or
        // an unknown attachment kind, outside the do/catch below so it surfaces rather than being
        // folded into `transactionError`.
        let transactionData = try StellarSendHelper.TransactionData.payment(
            asset: asset,
            amount: input.amountIn,
            accountId: deposit.address,
            memo: USwapMultiSwapApi.Attachment.memo(
                deposit.attachment,
                memoType: input.tokenIn.blockchainType.memoType
            )
        )

        var transactionError: Error?
        var fee: Decimal?

        do {
            let result = try await StellarSendHelper.preparePayment(
                asset: asset,
                amount: input.amountIn,
                adjustNativeBalance: false,
                accountId: deposit.address,
                stellarKit: adapter.stellarKit
            )

            fee = result.fee
        } catch {
            transactionError = error
        }

        return StellarSwapFinalQuote(
            amountIn: input.amountIn,
            expectedAmountOut: input.response.expectedBuyAmount,
            recipient: input.recipient,
            slippage: input.slippage,
            estimatedTime: input.response.estimatedTime,
            transactionData: transactionData,
            token: input.tokenIn,
            fee: fee,
            transactionError: transactionError,
            toAddress: input.destinationAddress,
            depositAddress: input.response.execution?.depositAddress,
            providerSwapId: input.providerSwapId
        )
    }
}
