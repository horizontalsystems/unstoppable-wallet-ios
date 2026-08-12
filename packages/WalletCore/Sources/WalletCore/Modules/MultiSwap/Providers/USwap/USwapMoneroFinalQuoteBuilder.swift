import Foundation
import MarketKit
import MoneroKit

final class USwapMoneroFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let adapterManager: AdapterManager

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType == .monero
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: input.tokenIn) as? MoneroAdapter else {
            throw USwapMultiSwapProvider.SwapError.noMoneroAdapter
        }
        guard let execution = input.response.execution else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }
        guard let deposit = execution.depositInstruction() else {
            throw USwapMultiSwapProvider.SwapError.invalidTransactionData
        }

        // Thrown, not folded into `transactionError`: a Monero memo never leaves this device — the
        // adapter hands it to MoneroKit, which stores it as a wallet user note against the tx id
        // (MONERO_Wallet_setUserNote), so the provider can never read the identifier it needs to
        // match this deposit. Same for a destination tag or an unknown attachment kind. A deposit
        // that silently loses it is unrecoverable.
        let memo = try USwapMultiSwapApi.Attachment.memo(
            deposit.attachment,
            memoType: input.tokenIn.blockchainType.memoType
        )

        let amount: MoneroSendAmount = adapter.balanceData.available == input.amountIn ? .all(input.amountIn) : .value(input.amountIn)
        let priority = input.transactionSettings?.moneroPriority ?? .default
        var fee: Decimal?
        var transactionError: Error?

        do {
            let estimatedFee = try adapter.estimateFee(
                amount: amount,
                address: deposit.address,
                priority: priority
            )

            fee = estimatedFee
            if input.amountIn + estimatedFee > adapter.balanceData.available {
                throw MoneroKit.MoneroCoreError.insufficientFunds(adapter.balanceData.available.description)
            }
        } catch {
            transactionError = error
        }

        return MoneroSwapFinalQuote(
            amountIn: input.amountIn,
            expectedAmountOut: input.response.expectedBuyAmount,
            recipient: input.recipient,
            slippage: input.slippage,
            estimatedTime: input.response.estimatedTime,
            amount: amount,
            address: deposit.address,
            memo: memo,
            token: input.tokenIn,
            priority: priority,
            fee: fee,
            transactionError: transactionError,
            toAddress: input.destinationAddress,
            depositAddress: input.response.execution?.depositAddress,
            providerSwapId: input.providerSwapId
        )
    }
}
