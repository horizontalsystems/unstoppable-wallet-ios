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
        guard let deposit = input.deposit else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }
        guard let adapterRecipient = adapter.recipient(from: deposit.address) else {
            throw SendTransactionError.invalidAddress
        }

        var transactionError: Error?
        var proposal: Proposal?
        var totalFeeRequired: Zatoshi?

        // A vault deposit (thorchain_deposit) whose vault publishes a shielded memo address: the
        // amount goes to the transparent inbound address and the memo rides a zero-value output to
        // the shielded address, where the vault decrypts it. Without that address the memo cannot
        // be delivered and the throw below applies.
        if case let .thorchainDeposit(_, _, memo, delivery) = input.response.execution,
           let shieldedMemoAddress = delivery.shieldedMemoAddress, !shieldedMemoAddress.isEmpty
        {
            // The amount output carries no memo and is matched by the vault on its transparent
            // inbound address. A shielded inbound address would hide the amount from the vault, so
            // the route is refused rather than sent.
            guard adapterRecipient.isTransparent else {
                throw USwapMultiSwapProvider.SwapError.invalidTransactionData
            }
            guard let memoRecipient = adapter.recipient(from: shieldedMemoAddress) else {
                throw SendTransactionError.invalidAddress
            }

            do {
                let amountOutput = ZcashAdapter.TransferOutput(
                    amount: input.amountIn.rounded(decimal: 8),
                    address: adapterRecipient,
                    memo: nil
                )
                let memoOutput = try ZcashAdapter.TransferOutput(
                    amount: 0,
                    address: memoRecipient,
                    memo: Memo(string: memo)
                )
                proposal = try await adapter.sendProposal(outputs: [amountOutput, memoOutput])
                totalFeeRequired = proposal?.totalFeeRequired()
            } catch {
                transactionError = error
            }

            return finalQuote(input: input, proposal: proposal, totalFeeRequired: totalFeeRequired, transactionError: transactionError)
        }

        // Thrown, not folded into `transactionError`: the memo below rides a ZIP-321 payment URI, so
        // a shielded deposit address encrypts it on-chain (unverifiable that the provider reads it)
        // and a transparent one carries no memo at all. Neither delivers the identifier, and a
        // deposit the provider cannot match is unrecoverable. Same for a destination tag or an
        // unknown attachment kind.
        let memoText = try USwapMultiSwapApi.Attachment.memo(
            deposit.attachment,
            memoType: input.tokenIn.blockchainType.memoType
        )

        do {
            let memo = try memoText.map { try Memo(string: $0) }
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

        return finalQuote(input: input, proposal: proposal, totalFeeRequired: totalFeeRequired, transactionError: transactionError)
    }

    private func finalQuote(
        input: USwapFinalQuoteFactory.Input,
        proposal: Proposal?,
        totalFeeRequired: Zatoshi?,
        transactionError: Error?
    ) -> SwapFinalQuote {
        ZcashSwapFinalQuote(
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
