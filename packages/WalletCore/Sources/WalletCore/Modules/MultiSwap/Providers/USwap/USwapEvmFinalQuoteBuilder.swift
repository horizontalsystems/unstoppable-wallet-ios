import BigInt
import EvmKit
import Foundation
import HsToolKit
import MarketKit

final class USwapEvmFinalQuoteBuilder: USwapFinalQuoteBuilder {
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmFeeEstimator: EvmFeeEstimator
    private let adapterManager: AdapterManager

    init(evmBlockchainManager: EvmBlockchainManager, evmFeeEstimator: EvmFeeEstimator, adapterManager: AdapterManager) {
        self.evmBlockchainManager = evmBlockchainManager
        self.evmFeeEstimator = evmFeeEstimator
        self.adapterManager = adapterManager
    }

    func supports(input: USwapFinalQuoteFactory.Input) -> Bool {
        input.tokenIn.blockchainType.isEvm
    }

    func build(input: USwapFinalQuoteFactory.Input) async throws -> SwapFinalQuote {
        let settingsGasPriceData = input.transactionSettings?.gasPriceData
        let transactionData: TransactionData
        let gasPrice: GasPrice?
        let predefinedGasLimit: Int?

        if let signable = input.response.execution?.primarySignable, signable.kind == "evm" {
            // Server-built transaction (signed routes, thorchain_deposit): signed
            // as the server priced it. The price comes from the tx — `gasPrice` for legacy, the
            // EIP-1559 pair otherwise — and the user's setting is only a fallback when it carries none.
            let jsonObject = signable.json

            guard let to = jsonObject["to"] as? String,
                  let dataString = jsonObject["data"] as? String,
                  let transactionInput = dataString.hs.hexData
            else {
                throw USwapMultiSwapProvider.SwapError.invalidTransactionData
            }

            // An absent `value` is 0 (ERC-20 calldata txs legitimately omit it); a present one must parse.
            let value: BigUInt
            if let rawValue = jsonObject["value"], !(rawValue is NSNull) {
                guard let parsed = Self.bigUInt(rawValue) else {
                    throw USwapMultiSwapProvider.SwapError.invalidTransactionData
                }
                value = parsed
            } else {
                value = 0
            }
            transactionData = try TransactionData(
                to: .init(hex: to),
                value: value,
                input: transactionInput
            )
            gasPrice = Self.gasPrice(json: jsonObject) ?? settingsGasPriceData?.userDefined
            predefinedGasLimit = Self.int(jsonObject["gas"])
        } else if let deposit = input.deposit {
            // Transfer route without a server tx: a plain native / ERC-20 transfer to the deposit (the
            // stub at preview, the real address after commit), priced with the user's setting.
            // Thrown, not folded into `transactionError`: an EVM transfer carries no memo, so a text
            // attachment would never reach the provider and the deposit would be unmatchable.
            _ = try USwapMultiSwapApi.Attachment.memo(deposit.attachment, memoType: input.tokenIn.blockchainType.memoType)

            guard let adapter = adapterManager.adapter(for: input.tokenIn) as? ISendEthereumAdapter else {
                throw USwapMultiSwapProvider.SwapError.noEvmAdapter
            }
            guard let rawAmount = input.tokenIn.rawAmount(input.amountIn) else {
                throw USwapMultiSwapProvider.SwapError.invalidTransactionData
            }

            transactionData = try adapter.transactionData(amount: rawAmount, address: EvmKit.Address(hex: deposit.address))
            gasPrice = settingsGasPriceData?.userDefined
            predefinedGasLimit = nil
        } else {
            throw USwapMultiSwapProvider.SwapError.noTransactionData
        }

        var evmFeeData: EvmFeeData?
        var transactionError: Error?

        if let evmKitWrapper = try evmBlockchainManager.evmKitManager(blockchainType: input.tokenIn.blockchainType).evmKitWrapper, let gasPrice {
            let gasPriceData = GasPriceData(recommended: settingsGasPriceData?.recommended ?? gasPrice, userDefined: gasPrice)

            do {
                let estimatedFeeData = try await evmFeeEstimator.estimateFee(
                    evmKitWrapper: evmKitWrapper,
                    transactionData: transactionData,
                    gasPriceData: gasPriceData,
                    predefinedGasLimit: predefinedGasLimit
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
            gasPrice: gasPrice,
            evmFeeData: evmFeeData,
            nonce: input.transactionSettings?.nonce,
            approval: approval,
            toAddress: input.destinationAddress,
            depositAddress: input.response.execution?.depositAddress,
            providerSwapId: input.providerSwapId
        )
    }

    // The price the server put on the tx: `gasPrice` (legacy) or the EIP-1559 pair; nil when it carries none.
    private static func gasPrice(json: [String: Any]) -> GasPrice? {
        if let maxFeePerGas = int(json["maxFeePerGas"]), let maxPriorityFeePerGas = int(json["maxPriorityFeePerGas"]) {
            return .eip1559(maxFeePerGas: maxFeePerGas, maxPriorityFeePerGas: maxPriorityFeePerGas)
        }
        if let gasPrice = int(json["gasPrice"]) {
            return .legacy(gasPrice: gasPrice)
        }
        return nil
    }

    // wei / gas values arrive as decimal or `0x`-hex strings (a bare number is tolerated too);
    // a zero or negative price / limit is treated as absent so the user setting / estimate applies
    private static func int(_ value: Any?) -> Int? {
        let parsed: Int?
        if let number = value as? NSNumber {
            parsed = number.intValue
        } else if let string = value as? String {
            if string.hasPrefix("0x") || string.hasPrefix("0X") {
                parsed = Int(string.dropFirst(2), radix: 16)
            } else {
                parsed = Int(string)
            }
        } else {
            parsed = nil
        }
        return parsed.flatMap { $0 > 0 ? $0 : nil }
    }

    // Same encoding rule as `int`, for the tx value (wei), which can exceed 64 bits: a decimal or
    // `0x`-hex string, or a bare JSON number taken through its decimal text so nothing is ever
    // truncated through a fixed-width accessor. nil when it does not parse (a bare `0x`, a negative,
    // a fraction, a bool).
    private static func bigUInt(_ value: Any) -> BigUInt? {
        if let number = value as? NSNumber {
            guard CFGetTypeID(number) != CFBooleanGetTypeID() else {
                return nil
            }
            return BigUInt(number.stringValue)
        }
        guard let string = value as? String else {
            return nil
        }
        if string.hasPrefix("0x") || string.hasPrefix("0X") {
            let hex = string.dropFirst(2)
            guard !hex.isEmpty else {
                return nil
            }
            return BigUInt(hex, radix: 16)
        }
        return BigUInt(string)
    }
}
