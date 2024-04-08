import BigInt
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import OneInchKit
import SwiftUI

class OneInchMultiSwapProvider: BaseEvmMultiSwapProvider {
    private let kit: OneInchKit.Kit
    private let networkManager = App.shared.networkManager
    private let evmFeeEstimator = EvmFeeEstimator()

    init(kit: OneInchKit.Kit, storage: MultiSwapSettingStorage) {
        self.kit = kit

        super.init(storage: storage)
    }

    override var id: String {
        "1inch"
    }

    override var name: String {
        "1Inch"
    }

    override var icon: String {
        "1inch_32"
    }

    override func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        guard tokenIn.blockchainType == tokenOut.blockchainType else {
            return false
        }

        switch tokenIn.blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom: return true
        default: return false
        }
    }

    override func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> IMultiSwapQuote {
        try await internalQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
    }

    override func confirmationQuote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal, transactionSettings: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        let quote = try await internalQuote(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)

        let blockchainType = tokenIn.blockchainType
        let gasPrice = transactionSettings?.gasPrice
        var evmFeeData: EvmFeeData?
        var resolvedSwap: Swap?
        var insufficientFeeBalance = false

        if let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper,
           let gasPrice,
           let amount = rawAmount(amount: amountIn, token: tokenIn)
        {
            let evmKit = evmKitWrapper.evmKit
            let swap = try await kit.swap(
                networkManager: networkManager,
                chain: evmKit.chain,
                receiveAddress: evmKit.receiveAddress,
                fromToken: address(token: tokenIn),
                toToken: address(token: tokenOut),
                amount: amount,
                slippage: slippage,
                recipient: storage.recipient(blockchainType: blockchainType).flatMap { try? EvmKit.Address(hex: $0.raw) },
                gasPrice: gasPrice
            )

            resolvedSwap = swap

            let evmBalance = evmKit.accountState?.balance ?? 0
            let txAmount = swap.transaction.value
            let feeAmount = BigUInt(swap.transaction.gasLimit * gasPrice.max)
            let totalAmount = txAmount + feeAmount

            insufficientFeeBalance = totalAmount > evmBalance

            evmFeeData = try await evmFeeEstimator.estimateFee(
                evmKitWrapper: evmKitWrapper,
                transactionData: swap.transactionData,
                gasPrice: gasPrice,
                predefinedGasLimit: swap.transaction.gasLimit
            )
        }

        return OneInchMultiSwapConfirmationQuote(
            quote: quote,
            swap: resolvedSwap,
            insufficientFeeBalance: insufficientFeeBalance,
            evmFeeData: evmFeeData,
            nonce: transactionSettings?.nonce
        )
    }

    override func settingsView(tokenIn: MarketKit.Token, tokenOut _: MarketKit.Token, onChangeSettings: @escaping () -> Void) -> AnyView {
        let view = ThemeNavigationView {
            RecipientAndSlippageMultiSwapSettingsView(tokenIn: tokenIn, storage: storage, onChangeSettings: onChangeSettings)
        }

        return AnyView(view)
    }

    override func swap(tokenIn: MarketKit.Token, tokenOut _: MarketKit.Token, amountIn _: Decimal, quote: IMultiSwapConfirmationQuote) async throws {
        guard let quote = quote as? OneInchMultiSwapConfirmationQuote else {
            throw SwapError.invalidQuote
        }

        guard let swap = quote.swap else {
            throw SwapError.invalidSwap
        }

        guard let gasLimit = quote.evmFeeData?.surchargedGasLimit else {
            throw SwapError.noGasLimit
        }

        guard let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: tokenIn.blockchainType).evmKitWrapper else {
            throw SwapError.noEvmKitWrapper
        }

        _ = try await evmKitWrapper.send(
            transactionData: swap.transactionData,
            gasPrice: swap.transaction.gasPrice,
            gasLimit: gasLimit,
            nonce: quote.nonce
        )
    }

    override func spenderAddress(chain: Chain) throws -> EvmKit.Address {
        try OneInchKit.Kit.routerAddress(chain: chain)
    }

    private func internalQuote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> OneInchMultiSwapQuote {
        let blockchainType = tokenIn.blockchainType
        let chain = evmBlockchainManager.chain(blockchainType: blockchainType)

        let addressFrom = try address(token: tokenIn)
        let addressTo = try address(token: tokenOut)

        guard let amount = rawAmount(amount: amountIn, token: tokenIn) else {
            throw SwapError.invalidAmountIn
        }

        let quote = try await kit.quote(
            networkManager: networkManager,
            chain: chain,
            fromToken: addressFrom,
            toToken: addressTo,
            amount: amount
        )

        return await OneInchMultiSwapQuote(
            quote: quote,
            recipient: storage.recipient(blockchainType: blockchainType),
            slippage: slippage,
            allowanceState: allowanceState(token: tokenIn, amount: amountIn)
        )
    }

    private func address(token: MarketKit.Token) throws -> EvmKit.Address {
        switch token.type {
        case .native: return try EvmKit.Address(hex: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
        case let .eip20(address): return try EvmKit.Address(hex: address)
        default: throw SwapError.invalidAddress
        }
    }

    private func rawAmount(amount: Decimal, token: MarketKit.Token) -> BigUInt? {
        let rawAmountString = (amount * pow(10, token.decimals)).hs.roundedString(decimal: 0)
        return BigUInt(rawAmountString)
    }

    private var slippage: Decimal {
        storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.default
    }
}

extension OneInchMultiSwapProvider {
    enum SwapError: Error {
        case invalidAddress
        case invalidAmountIn
        case invalidQuote
        case invalidSwap
        case noEvmKitWrapper
        case noGasLimit
    }
}

extension Swap {
    var transactionData: TransactionData {
        TransactionData(to: transaction.to, value: transaction.value, input: transaction.data)
    }
}
