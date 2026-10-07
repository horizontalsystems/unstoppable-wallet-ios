import Foundation
import MarketKit
import TonKit
import TonSwift

final class USwapTonFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let accountManager: AccountManager
    private let adapterManager: AdapterManager

    init(accountManager: AccountManager, adapterManager: AdapterManager) {
        self.accountManager = accountManager
        self.adapterManager = adapterManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType == .ton
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        guard let account = accountManager.activeAccount else {
            throw USwapMultiSwapProvider.SwapError.noTonAdapter
        }

        if let signable = input.response.execution?.primarySignable, signable.kind == "ton",
           let jsonObject = signable.innerTx
        {
            return try await buildParam(input: input, account: account, jsonObject: jsonObject)
        }

        guard let deposit = input.deposit else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }

        return try await buildTransfer(input: input, account: account, deposit: deposit)
    }

    // server-built transaction: emulate and sign as is
    private func buildParam(input: USwapFinalQuoteFactory.Input, account: Account, jsonObject: Any) async throws -> SwapFinalQuote {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
        let transactionParam = try JSONDecoder().decode(SendTransactionParam.self, from: jsonData)

        var transactionError: Error?
        var fee: Decimal?

        do {
            let (publicKey, _) = try TonKitManager.keyPair(accountType: account.type)
            let contract = TonKitManager.contract(publicKey: publicKey)
            let transferData = try TonSendHelper.transferData(
                param: transactionParam,
                contract: contract
            )

            fee = try await emulate(transferData: transferData, contract: contract)
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

    // Plain TON / jetton transfer to the deposit (the stub at preview, the real address after commit),
    // built through the send adapter exactly as the TON send form does; the comment carries the memo.
    private func buildTransfer(input: USwapFinalQuoteFactory.Input, account: Account, deposit: USwapFinalQuoteFactory.Input.Deposit) async throws -> SwapFinalQuote {
        // Thrown, not folded into `transactionError`: only a text memo rides a TON comment; a
        // destination tag or an unknown attachment kind would leave the deposit unmatchable.
        let comment = try USwapMultiSwapApi.Attachment.memo(deposit.attachment, memoType: input.tokenIn.blockchainType.memoType)

        guard let adapter = adapterManager.adapter(for: input.tokenIn) as? ISendTonAdapter else {
            throw USwapMultiSwapProvider.SwapError.noTonAdapter
        }

        let recipient = try FriendlyAddress(string: deposit.address)

        var transactionError: Error?
        var fee: Decimal?

        do {
            let (publicKey, _) = try TonKitManager.keyPair(accountType: account.type)
            let contract = TonKitManager.contract(publicKey: publicKey)
            let transferData = try adapter.transferData(
                recipient: recipient,
                amount: .amount(value: input.amountIn),
                comment: comment
            )

            fee = try await emulate(transferData: transferData, contract: contract)
        } catch {
            transactionError = error
        }

        return TonSwapFinalQuote(
            amountIn: input.amountIn,
            expectedAmountOut: input.response.expectedBuyAmount,
            recipient: input.recipient,
            slippage: input.slippage,
            estimatedTime: input.response.estimatedTime,
            transactionParam: nil,
            transfer: TonTransferExecution(recipient: recipient, amount: input.amountIn, comment: comment),
            fee: fee,
            transactionError: transactionError,
            toAddress: input.destinationAddress,
            depositAddress: input.response.execution?.depositAddress,
            providerSwapId: input.providerSwapId
        )
    }

    private func emulate(transferData: TransferData, contract: WalletContract) async throws -> Decimal {
        let emulationResult = try await TonSendHelper.emulate(
            transferData: transferData,
            contract: contract,
            converter: nil
        )

        try await TonSendHelper.validateBalance(
            address: contract.address(),
            totalValue: emulationResult.totalValue,
            fee: TonAdapter.kitAmount(amount: emulationResult.fee)
        )

        return emulationResult.fee
    }
}
