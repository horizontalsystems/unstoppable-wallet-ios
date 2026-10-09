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

        let execution = input.response.execution

        if case .signedTransaction = execution {
            guard let signable = execution?.primarySignable, signable.kind == "stellar", let xdr = signable.xdr else {
                throw USwapMultiSwapProvider.SwapError.invalidTransactionData
            }

            let fee = (try? TransactionEnvelopeXDR(fromBase64: xdr)).map {
                Decimal($0.txFee) / 10_000_000
            }

            let transactionError = balanceError(adapter: adapter, tokenIn: input.tokenIn, amountIn: input.amountIn, fee: fee ?? 0)

            return StellarSwapFinalQuote(
                amountIn: input.amountIn,
                expectedAmountOut: input.response.expectedBuyAmount,
                recipient: input.recipient,
                slippage: input.slippage,
                estimatedTime: input.response.estimatedTime,
                transactionData: .envelope(xdr),
                token: input.tokenIn,
                fee: fee,
                transactionError: transactionError,
                toAddress: input.destinationAddress,
                providerSwapId: input.providerSwapId
            )
        }

        guard let deposit = input.deposit else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
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
        // Known before any check, so the fee row stays even when the deposit is refused (as Android)
        let fee: Decimal? = try? await adapter.stellarKit.baseFee()

        do {
            _ = try await StellarSendHelper.preparePayment(
                asset: asset,
                amount: input.amountIn,
                adjustNativeBalance: false,
                accountId: deposit.address,
                stellarKit: adapter.stellarKit
            )
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

    /// Pre-flight balance check so the confirm screen shows the standard insufficient-balance
    /// caution instead of failing at send. Two legs: the SELL asset itself (the adapter is
    /// per-token — `balanceData.available` is that asset's balance, reserve-adjusted for
    /// native), and the native XLM needed for fees.
    private func balanceError(adapter: StellarAdapter, tokenIn: Token, amountIn: Decimal, fee: Decimal) -> Error? {
        if tokenIn.type != .native {
            let assetAvailable = adapter.balanceData.available
            guard assetAvailable >= amountIn else {
                return StellarSendHelper.TransactionError.insufficientStellarBalance(balance: assetAvailable)
            }
        }
        let availableNative = adapter.stellarKit.account?.availableBalance ?? 0
        let requiredNative = tokenIn.type == .native ? amountIn + fee : fee
        guard availableNative >= requiredNative else {
            return StellarSendHelper.TransactionError.insufficientStellarBalance(balance: availableNative)
        }
        return nil
    }
}
