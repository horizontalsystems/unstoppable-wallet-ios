import Foundation
import MarketKit
import NearKit

final class USwapNearFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let adapterManager: AdapterManager

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType == .near
    }

    /// A deposit-address transfer: NEAR, or `ft_transfer` for a NEP-141 token (Android `USwapProvider`,
    /// `depositType = ORIGIN_CHAIN`).
    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: input.tokenIn) as? ISendNearAdapter & IBalanceAdapter else {
            throw USwapMultiSwapProvider.SwapError.noNearAdapter
        }
        guard let deposit = input.deposit else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }

        // Thrown, not folded into `transactionError`: a NEAR deposit carries no memo, so a route that
        // needs one would leave the deposit unmatchable, and an unmatched deposit is unrecoverable
        // (Android `memoDelivery = None`).
        _ = try USwapMultiSwapApi.Attachment.memo(deposit.attachment, memoType: BlockchainType.near.memoType)
        try NearKit.Kit.validate(accountId: deposit.address)

        // the deposit address may be a token's unregistered receiver: its storage deposit is in the estimate
        let estimation = await NearSendHelper.estimation(
            adapter: adapter, token: input.tokenIn, amount: input.amountIn, address: deposit.address, memo: nil,
            tokenBalance: adapter.balanceData.available
        )

        return NearSwapFinalQuote(
            token: input.tokenIn,
            address: deposit.address,
            amount: input.amountIn,
            estimate: estimation.estimate,
            fee: estimation.estimate?.fee ?? adapter.fee,
            previousTransactionPending: !adapter.pendingTransactionHashes.isEmpty,
            expectedAmountOut: input.response.expectedBuyAmount,
            recipient: input.recipient,
            slippage: input.slippage,
            estimatedTime: input.response.estimatedTime,
            transactionError: estimation.transactionError,
            toAddress: input.destinationAddress,
            depositAddress: input.response.execution?.depositAddress,
            providerSwapId: input.providerSwapId
        )
    }
}
