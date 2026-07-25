import Foundation
import MarketKit
import TonKit

final class USwapTonFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let accountManager: AccountManager

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType == .ton
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        guard let signable = input.response.execution?.primarySignable, signable.kind == "ton",
              let jsonObject = signable.innerTx
        else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }

        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
        let transactionParam = try JSONDecoder().decode(SendTransactionParam.self, from: jsonData)

        var transactionError: Error?
        var fee: Decimal?

        guard let account = accountManager.activeAccount else {
            throw USwapMultiSwapProvider.SwapError.noTonAdapter
        }

        do {
            let (publicKey, _) = try TonKitManager.keyPair(accountType: account.type)
            let contract = TonKitManager.contract(publicKey: publicKey)
            let transferData = try TonSendHelper.transferData(
                param: transactionParam,
                contract: contract
            )
            let emulationResult = try await TonSendHelper.emulate(
                transferData: transferData,
                contract: contract,
                converter: nil
            )

            fee = emulationResult.fee

            try await TonSendHelper.validateBalance(
                address: contract.address(),
                totalValue: emulationResult.totalValue,
                fee: TonAdapter.kitAmount(amount: emulationResult.fee)
            )
        } catch {
            transactionError = error
        }

        return TonSwapFinalQuote(
            amountIn: input.amountIn,
            expectedAmountOut: input.response.expectedBuyAmount,
            recipient: input.recipient,
            slippage: input.slippage,
            estimatedTime: input.response.estimatedTime,
            transactionParam: transactionParam,
            fee: fee,
            transactionError: transactionError,
            toAddress: input.destinationAddress,
            depositAddress: input.response.execution?.depositAddress,
            providerSwapId: input.providerSwapId
        )
    }
}
