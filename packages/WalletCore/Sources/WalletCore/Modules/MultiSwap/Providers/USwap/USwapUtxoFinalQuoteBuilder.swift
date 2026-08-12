import BitcoinCore
import MarketKit

final class USwapUtxoFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let adapterManager: AdapterManager

    init(adapterManager: AdapterManager) {
        self.adapterManager = adapterManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        switch input.tokenIn.blockchainType {
        case .bitcoin, .bitcoinCash, .ecash, .litecoin, .dash: true
        default: false
        }
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        var transactionError: Error?
        var sendInfo: SendInfo?
        var params: SendParameters?

        guard let execution = input.response.execution else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }
        guard let deposit = execution.depositInstruction() else {
            throw USwapMultiSwapProvider.SwapError.invalidTransactionData
        }

        // A text memo IS deliverable here and must keep working: it reaches BitcoinCore's
        // OutputSetter, which broadcasts it as a plain OP_RETURN output the provider can read. It
        // travels on `params` below, and `canSwap` requires those, so it can never be sent without.
        // Still throws on a destination tag or an unknown attachment kind.
        let memo = try USwapMultiSwapApi.Attachment.memo(
            deposit.attachment,
            memoType: input.tokenIn.blockchainType.memoType
        )

        if let satoshiPerByte = input.transactionSettings?.satoshiPerByte,
           let adapter = adapterManager.adapter(for: input.tokenIn) as? BitcoinBaseAdapter
        {
            do {
                let value = adapter.convertToSatoshi(value: input.amountIn)
                let sendParameters = SendParameters(
                    address: deposit.address,
                    value: value,
                    feeRate: satoshiPerByte,
                    memo: memo
                )

                sendInfo = try adapter.sendInfo(params: sendParameters)
                params = sendParameters
            } catch {
                transactionError = error
            }
        }

        return UtxoSwapFinalQuote(
            expectedBuyAmount: input.response.expectedBuyAmount,
            sendParameters: params,
            slippage: input.slippage,
            recipient: input.recipient,
            estimatedTime: input.response.estimatedTime,
            transactionError: transactionError,
            fee: sendInfo?.fee,
            toAddress: input.destinationAddress,
            depositAddress: deposit.address,
            providerSwapId: input.providerSwapId
        )
    }
}
