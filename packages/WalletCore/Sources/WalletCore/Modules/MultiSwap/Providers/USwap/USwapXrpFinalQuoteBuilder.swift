import Foundation
import MarketKit
import XrpKit

final class USwapXrpFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let adapterManager: AdapterManager

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType == .xrp
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: input.tokenIn) as? ISendXrpAdapter else {
            throw USwapMultiSwapProvider.SwapError.noXrpAdapter
        }
        guard let execution = input.response.execution else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }
        guard let deposit = execution.depositInstruction() else {
            throw USwapMultiSwapProvider.SwapError.invalidTransactionData
        }

        // Thrown, not folded into `transactionError`: on XRP the provider credits the deposit by
        // the Payment's DestinationTag, never by a memo, so a text attachment has nowhere to go
        // and a tag the field cannot hold would be truncated into somebody else's order. Either
        // way the deposit would be unmatchable, and an unmatched deposit is unrecoverable.
        let attachmentTag = try USwapMultiSwapApi.Attachment.destinationTag(deposit.attachment)

        // A deposit address may itself be an X-address carrying the tag; a tag on both sides that
        // disagrees fails the route rather than picking one.
        let destination = try XrpKit.Kit.resolveDestination(address: deposit.address, tag: attachmentTag, network: XrpKitManager.network)

        let fee = adapter.fee
        var transactionError: Error?

        if input.amountIn + fee > adapter.availableXrpBalance {
            transactionError = XrpSendHelper.TransactionError.insufficientXrpBalance(balance: adapter.availableXrpBalance)
        } else {
            transactionError = await XrpSendHelper.destinationError(
                adapter: adapter, token: input.tokenIn, amount: input.amountIn,
                address: destination.classic, destinationTag: destination.tag
            )
        }

        return XrpSwapFinalQuote(
            token: input.tokenIn,
            address: destination.classic,
            amount: input.amountIn,
            destinationTag: destination.tag,
            expectedAmountOut: input.response.expectedBuyAmount,
            recipient: input.recipient,
            slippage: input.slippage,
            estimatedTime: input.response.estimatedTime,
            fee: fee,
            transactionError: transactionError,
            toAddress: input.destinationAddress,
            depositAddress: input.response.execution?.depositAddress,
            providerSwapId: input.providerSwapId
        )
    }
}
