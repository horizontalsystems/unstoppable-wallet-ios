import Foundation
import MarketKit

final class USwapSolanaFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let adapterManager: AdapterManager

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType == .solana
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: input.tokenIn) as? ISendSolanaAdapter & IBalanceAdapter else {
            throw USwapMultiSwapProvider.SwapError.noSolanaAdapter
        }
        guard let signable = input.response.execution?.primarySignable, signable.kind == "solana",
              let txString = signable.message,
              let rawTransaction = Data(base64Encoded: txString)
        else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }

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
}
