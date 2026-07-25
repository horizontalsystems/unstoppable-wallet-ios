import BigInt
import EvmKit
import HsToolKit
import MarketKit

final class USwapEvmFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmFeeEstimator: EvmFeeEstimator

    init(evmBlockchainManager: EvmBlockchainManager, evmFeeEstimator: EvmFeeEstimator) {
        self.evmBlockchainManager = evmBlockchainManager
        self.evmFeeEstimator = evmFeeEstimator
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType.isEvm
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        guard let signable = input.response.execution?.primarySignable, signable.kind == "evm" else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }
        let jsonObject = signable.json

        guard let to = jsonObject["to"] as? String,
              let valueString = jsonObject["value"] as? String,
              let dataString = jsonObject["data"] as? String,
              let transactionInput = dataString.hs.hexData
        else {
            throw USwapMultiSwapProvider.SwapError.invalidTransactionData
        }

        let gasLimitData: Int? = (jsonObject["gas"] as? String).flatMap {
            let hex = $0.stripping(prefix: "0x")
            return Int(hex, radix: 16)
        }

        let value = BigUInt(valueString.stripping(prefix: "0x"), radix: 16) ?? BigUInt(0)
        let transactionData = try TransactionData(
            to: .init(hex: to),
            value: value,
            input: transactionInput
        )

        let gasPriceData = input.transactionSettings?.gasPriceData
        var evmFeeData: EvmFeeData?
        var transactionError: Error?

        if let evmKitWrapper = try evmBlockchainManager.evmKitManager(blockchainType: input.tokenIn.blockchainType).evmKitWrapper, let gasPriceData {
            do {
                let estimatedFeeData = try await evmFeeEstimator.estimateFee(
                    evmKitWrapper: evmKitWrapper,
                    transactionData: transactionData,
                    gasPriceData: gasPriceData,
                    predefinedGasLimit: gasLimitData
                )
                evmFeeData = estimatedFeeData

                try BaseEvmMultiSwapProvider.validateBalance(
                    evmKitWrapper: evmKitWrapper,
                    transactionData: transactionData,
                    evmFeeData: estimatedFeeData,
                    gasPriceData: gasPriceData
                )
            } catch {
                transactionError = error
            }
        }

        let approval = input.response.approvalSpender
            .flatMap { try? EvmKit.Address(hex: $0) }
            .flatMap { SwapApproval.build(spender: $0, tokenIn: input.tokenIn, amountIn: input.amountIn) }

        return EvmSwapFinalQuote(
            expectedBuyAmount: input.response.expectedBuyAmount,
            transactionData: transactionData,
            transactionError: transactionError,
            slippage: input.slippage,
            recipient: input.recipient,
            estimatedTime: input.response.estimatedTime,
            gasPrice: gasPriceData?.userDefined,
            evmFeeData: evmFeeData,
            nonce: input.transactionSettings?.nonce,
            approval: approval,
            toAddress: input.destinationAddress,
            depositAddress: input.response.execution?.depositAddress,
            providerSwapId: input.providerSwapId
        )
    }
}
