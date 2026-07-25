import HsToolKit
import MarketKit
import ZcashLightClientKit

final class USwapZcashFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let adapterManager: AdapterManager

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType == .zcash
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        guard let adapter = adapterManager.adapter(for: input.tokenIn) as? ZcashAdapter else {
            throw USwapMultiSwapProvider.SwapError.noZcashAdapter
        }
        guard let execution = input.response.execution else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }
        guard let deposit = execution.depositInstruction() else {
            throw USwapMultiSwapProvider.SwapError.invalidTransactionData
        }
        guard let adapterRecipient = adapter.recipient(from: deposit.address) else {
            throw SendTransactionError.invalidAddress
        }

        var transactionError: Error?
        var proposal: Proposal?
        var totalFeeRequired: Zatoshi?

        do {
            let memo = try deposit.memo.map { try Memo(string: $0) }
            let output = ZcashAdapter.TransferOutput(
                amount: input.amountIn.rounded(decimal: 8),
                address: adapterRecipient,
                memo: memo
            )
            proposal = try await adapter.sendProposal(outputs: [output])
            totalFeeRequired = proposal?.totalFeeRequired()
        } catch {
            transactionError = error
        }

        return ZcashSwapFinalQuote(
            expectedBuyAmount: input.response.expectedBuyAmount,
            proposal: proposal,
            slippage: input.slippage,
            recipient: input.recipient,
            estimatedTime: input.response.estimatedTime,
            transactionError: transactionError,
            fee: totalFeeRequired?.decimalValue.decimalValue,
            toAddress: input.destinationAddress,
            depositAddress: input.response.execution?.depositAddress,
            providerSwapId: input.providerSwapId
        )
    }
}
