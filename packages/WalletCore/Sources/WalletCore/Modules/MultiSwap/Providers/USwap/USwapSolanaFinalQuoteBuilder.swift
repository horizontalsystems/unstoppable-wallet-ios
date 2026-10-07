import Foundation
import MarketKit

final class USwapSolanaFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let adapterManager: AdapterManager
    private let solanaKitManager: SolanaKitManager

    init(adapterManager: AdapterManager, solanaKitManager: SolanaKitManager) {
        self.adapterManager = adapterManager
        self.solanaKitManager = solanaKitManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType == .solana
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: input.tokenIn) as? ISendSolanaAdapter & IBalanceAdapter else {
            throw USwapMultiSwapProvider.SwapError.noSolanaAdapter
        }

        if let signable = input.response.execution?.primarySignable, signable.kind == "solana",
           let txString = signable.message,
           let rawTransaction = Data(base64Encoded: txString)
        {
            return buildRaw(input: input, adapter: adapter, rawTransaction: rawTransaction)
        }

        guard let deposit = input.deposit else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }

        return try buildTransfer(input: input, adapter: adapter, deposit: deposit)
    }

    // server-built transaction message: estimate and sign as is
    private func buildRaw(input: USwapFinalQuoteFactory.Input, adapter: ISendSolanaAdapter & IBalanceAdapter, rawTransaction: Data) -> SwapFinalQuote {
        var transactionError: Error?
        var fee: Decimal?

        do {
            let estimatedFee = try adapter.estimateFee(rawTransaction: rawTransaction)
            fee = estimatedFee

            let totalRequired = (input.tokenIn.type.isNative ? input.amountIn : 0) + estimatedFee
            if adapter.balanceData.available < totalRequired {
                throw SolanaSendHandler.TransactionError.insufficientSolBalance(balance: adapter.balanceData.available)
            }
        } catch {
            transactionError = error
        }

        return SolanaSwapFinalQuote(
            rawTransaction: rawTransaction,
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

    // Plain SOL / SPL transfer to the deposit (the stub at preview, the real address after commit),
    // checked exactly as the Solana send form does.
    private func buildTransfer(input: USwapFinalQuoteFactory.Input, adapter: ISendSolanaAdapter & IBalanceAdapter, deposit: USwapFinalQuoteFactory.Input.Deposit) throws -> SwapFinalQuote {
        // Thrown, not folded into `transactionError`: a memo cannot ride `sendSol` / `sendSpl`, so an
        // attachment of any kind would be dropped and the deposit would be unmatchable.
        if try USwapMultiSwapApi.Attachment.memo(deposit.attachment, memoType: input.tokenIn.blockchainType.memoType) != nil {
            throw USwapMultiSwapApi.Attachment.AttachmentError.unsupported
        }

        let fee = adapter.fee
        var transactionError: Error?

        if input.tokenIn.type.isNative {
            let solBalance = adapter.balanceData.available
            if input.amountIn + fee > solBalance {
                transactionError = SolanaSendHandler.TransactionError.insufficientSolBalance(balance: solBalance)
            }
        } else {
            // SPL token: SOL covers the fee, the token covers the amount
            let solBalance = solanaKitManager.solanaKit?.balance ?? 0
            if solBalance < fee {
                transactionError = SolanaSendHandler.TransactionError.insufficientSolBalance(balance: solBalance)
            }
        }

        return SolanaSwapFinalQuote(
            rawTransaction: nil,
            transfer: SolanaTransferExecution(toAddress: deposit.address, amount: input.amountIn),
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
