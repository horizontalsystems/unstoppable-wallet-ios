import BigInt
import MarketKit
import ObjectMapper
import TronKit

final class USwapTronFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let tronKitManager: TronKitManager
    private let adapterManager: AdapterManager

    init(tronKitManager: TronKitManager, adapterManager: AdapterManager) {
        self.tronKitManager = tronKitManager
        self.adapterManager = adapterManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType == .tron
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        if let signable = input.response.execution?.primarySignable, signable.kind == "tron",
           let jsonObject = signable.innerTx as? [String: Any]
        {
            return try await buildCreated(input: input, jsonObject: jsonObject)
        }

        guard let deposit = input.deposit else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }

        return try await buildTransfer(input: input, deposit: deposit)
    }

    // server-built transaction: estimate and sign as is
    private func buildCreated(input: USwapFinalQuoteFactory.Input, jsonObject: [String: Any]) async throws -> SwapFinalQuote {
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

        return TronSwapFinalQuote(
            amountIn: input.amountIn,
            expectedAmountOut: input.response.expectedBuyAmount,
            recipient: input.recipient,
            slippage: input.slippage,
            estimatedTime: input.response.estimatedTime,
            createdTransaction: transaction,
            transferIntent: transferIntent(input: input),
            fees: fees,
            transactionError: transactionError,
            toAddress: input.destinationAddress,
            depositAddress: input.response.execution?.depositAddress,
            providerSwapId: input.providerSwapId
        )
    }

    // Plain TRX / TRC-20 transfer to the deposit (the stub at preview, the real address after commit),
    // built through the send adapter exactly as the Tron send form does.
    private func buildTransfer(input: USwapFinalQuoteFactory.Input, deposit: USwapFinalQuoteFactory.Input.Deposit) async throws -> SwapFinalQuote {
        // Thrown, not folded into `transactionError`: a Tron transfer carries no memo, so a text
        // attachment would never reach the provider and the deposit would be unmatchable.
        let memo = try USwapMultiSwapApi.Attachment.memo(deposit.attachment, memoType: input.tokenIn.blockchainType.memoType)

        guard let tronKitWrapper = tronKitManager.tronKitWrapper,
              let adapter = adapterManager.adapter(for: input.tokenIn) as? ISendTronAdapter
        else {
            throw USwapMultiSwapProvider.SwapError.noTronAdapter
        }
        guard let rawAmount = input.tokenIn.rawAmount(input.amountIn) else {
            throw USwapMultiSwapProvider.SwapError.invalidTransactionData
        }

        let tronKit = tronKitWrapper.tronKit
        let contract = try adapter.contract(amount: rawAmount, address: TronKit.Address(address: deposit.address), memo: memo)

        var fees: [TronKit.Fee] = []
        var transfer: TronTransferExecution?
        var transactionError: Error?

        do {
            if !input.tokenIn.type.isNative, adapter.balanceData.available < input.amountIn {
                throw TronSendHelper.TransactionError.insufficientTokenBalance(balance: adapter.balanceData.available, token: input.tokenIn)
            }

            let estimatedFees = try await tronKit.estimateFee(contract: contract)
            let totalFees = estimatedFees.calculateTotalFees()

            // the amount is the provider's: no max-amount reduction, a shortfall is an error
            var totalAmount = BigUInt(totalFees)
            if input.tokenIn.type.isNative {
                totalAmount += rawAmount
            }

            if tronKit.trxBalance < totalAmount {
                throw TronSendHelper.TransactionError.insufficientBalance(balance: tronKit.trxBalance)
            }

            fees = estimatedFees
            transfer = TronTransferExecution(contract: contract, feeLimit: totalFees)
        } catch {
            transactionError = error
        }

        return TronSwapFinalQuote(
            amountIn: input.amountIn,
            expectedAmountOut: input.response.expectedBuyAmount,
            recipient: input.recipient,
            slippage: input.slippage,
            estimatedTime: input.response.estimatedTime,
            createdTransaction: nil,
            transfer: transfer,
            transferIntent: transferIntent(input: input),
            fees: fees,
            transactionError: transactionError,
            toAddress: input.destinationAddress,
            depositAddress: input.response.execution?.depositAddress,
            providerSwapId: input.providerSwapId
        )
    }

    private func transferIntent(input: USwapFinalQuoteFactory.Input) -> TronTransferIntent? {
        guard let depositAddress = input.response.execution?.depositAddress,
              case let .eip20(tokenAddress) = input.tokenIn.type,
              let token = try? TronKit.Address(address: tokenAddress),
              let receiver = try? TronKit.Address(address: depositAddress),
              let value = input.tokenIn.rawAmount(input.amountIn)
        else {
            return nil
        }

        return TronTransferIntent(token: token, receiver: receiver, value: value)
    }
}
