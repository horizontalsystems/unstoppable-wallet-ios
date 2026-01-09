import BigInt
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import OneInchKit
import SwiftUI

class OneInchMultiSwapProvider: BaseEvmMultiSwapProvider {
    private let kit: OneInchKit.Kit
    private let networkManager = Core.shared.networkManager
    private let evmFeeEstimator = EvmFeeEstimator()
    private let commission: Decimal? = AppConfig.oneInchCommission
    private let commissionAddress: String? = AppConfig.oneInchCommissionAddress

    init(kit: OneInchKit.Kit) {
        self.kit = kit

        super.init()
    }

    override var id: String { "1inch" }
    override var name: String { "1Inch" }
    override var description: String { "DEX" }
    override var icon: String { "swap_provider_1inch" }

    override func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        guard tokenIn.blockchainType == tokenOut.blockchainType else {
            return false
        }

        switch tokenIn.blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom, .base: return true
        default: return false
        }
    }

    override func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> MultiSwapQuote {
        let blockchainType = tokenIn.blockchainType
        let chain = try evmBlockchainManager.chain(blockchainType: blockchainType)

        let addressFrom = try address(token: tokenIn)
        let addressTo = try address(token: tokenOut)

        guard let amount = tokenIn.rawAmount(amountIn) else {
            throw SwapError.invalidAmountIn
        }

        let quote = try await kit.quote(
            networkManager: networkManager,
            chain: chain,
            fromToken: addressFrom,
            toToken: addressTo,
            amount: amount,
            fee: commission
        )

        return await EvmMultiSwapQuote(
            expectedBuyAmount: quote.amountOut ?? 0,
            allowanceState: allowanceState(token: tokenIn, amount: amountIn)
        )
    }

    override func confirmationQuote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal, slippage: Decimal, recipient: String?, transactionSettings: TransactionSettings?) async throws -> ISwapFinalQuote {
        let blockchainType = tokenIn.blockchainType

        guard let evmKitWrapper = try evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper else {
            throw SwapError.noEvmKitWrapper
        }

        guard let gasPriceData = transactionSettings?.gasPriceData else {
            throw SwapError.noGasPriceData
        }

        guard let amount = tokenIn.rawAmount(amountIn) else {
            throw SwapError.invalidAmountIn
        }

        let evmKit = evmKitWrapper.evmKit

        let swap = try await kit.swap(
            networkManager: networkManager,
            chain: evmKit.chain,
            receiveAddress: evmKit.receiveAddress,
            fromToken: address(token: tokenIn),
            toToken: address(token: tokenOut),
            amount: amount,
            slippage: slippage,
            referrer: commissionAddress,
            fee: commission,
            recipient: recipient.flatMap { try? EvmKit.Address(hex: $0) },
            gasPrice: gasPriceData.userDefined
        )

        let evmBalance = evmKit.accountState?.balance ?? 0
        let txAmount = swap.transaction.value
        let feeAmount = BigUInt(swap.transaction.gasLimit * gasPriceData.userDefined.max)
        let totalAmount = txAmount + feeAmount
        let transactionError: Error? = totalAmount > evmBalance ? AppError.ethereum(reason: .insufficientBalanceWithFee) : nil

        let evmFeeData = try await evmFeeEstimator.estimateFee(
            evmKitWrapper: evmKitWrapper,
            transactionData: swap.transactionData,
            gasPriceData: gasPriceData,
            predefinedGasLimit: swap.transaction.gasLimit
        )

        return EvmSwapFinalQuote(
            expectedBuyAmount: swap.amountOut ?? 0,
            transactionData: swap.transactionData,
            transactionError: transactionError,
            slippage: slippage,
            recipient: recipient,
            gasPrice: swap.transaction.gasPrice,
            evmFeeData: evmFeeData,
            nonce: transactionSettings?.nonce
        )
    }

    override func spenderAddress(chain: Chain) throws -> EvmKit.Address {
        try OneInchKit.Kit.routerAddress(chain: chain)
    }

    private func address(token: MarketKit.Token) throws -> EvmKit.Address {
        switch token.type {
        case .native: return try EvmKit.Address(hex: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
        case let .eip20(address): return try EvmKit.Address(hex: address)
        default: throw SwapError.invalidAddress
        }
    }
}

extension OneInchMultiSwapProvider {
    enum SwapError: Error {
        case invalidAddress
        case invalidAmountIn
        case invalidQuote
        case noEvmKitWrapper
        case noGasPriceData
    }
}

extension Swap {
    var transactionData: TransactionData {
        TransactionData(to: transaction.to, value: transaction.value, input: transaction.data)
    }
}
