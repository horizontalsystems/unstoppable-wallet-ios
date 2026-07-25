import MarketKit
import ObjectMapper
import TronKit

final class USwapTronFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let tronKitManager: TronKitManager

    init(tronKitManager: TronKitManager) {
        self.tronKitManager = tronKitManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType == .tron
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        guard let signable = input.response.execution?.primarySignable, signable.kind == "tron",
              let jsonObject = signable.innerTx as? [String: Any]
        else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }

        let transaction = try Mapper<CreatedTransactionResponse>().map(JSON: jsonObject)

        var fees: [TronKit.Fee] = []
        var transactionError: Error?

        if let tronKitWrapper = tronKitManager.tronKitWrapper {
            do {
                let result = try await TronSendHelper.estimateFees(
                    createdTransaction: transaction,
                    tronKit: tronKitWrapper.tronKit,
                    tokenIn: input.tokenIn,
                    amountIn: input.amountIn
                )

                fees = result.fees
                transactionError = result.transactionError
            } catch {
                transactionError = error
            }
        }

        var transferIntent: TronTransferIntent?
        if let depositAddress = input.response.execution?.depositAddress,
           case let .eip20(tokenAddress) = input.tokenIn.type,
           let token = try? TronKit.Address(address: tokenAddress),
           let receiver = try? TronKit.Address(address: depositAddress),
           let value = input.tokenIn.rawAmount(input.amountIn)
        {
            transferIntent = TronTransferIntent(token: token, receiver: receiver, value: value)
        }

        return TronSwapFinalQuote(
            amountIn: input.amountIn,
            expectedAmountOut: input.response.expectedBuyAmount,
            recipient: input.recipient,
            slippage: input.slippage,
            estimatedTime: input.response.estimatedTime,
            createdTransaction: transaction,
            transferIntent: transferIntent,
            fees: fees,
            transactionError: transactionError,
            toAddress: input.destinationAddress,
            depositAddress: input.response.execution?.depositAddress,
            providerSwapId: input.providerSwapId
        )
    }
}
