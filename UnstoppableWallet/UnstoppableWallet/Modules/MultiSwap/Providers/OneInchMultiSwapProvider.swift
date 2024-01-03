import BigInt
import EvmKit
import Foundation
import MarketKit
import OneInchKit
import SwiftUI

struct OneInchMultiSwapProvider {
    private let kit: OneInchKit.Kit
    private let storage: MultiSwapSettingStorage
    private let marketKit = App.shared.marketKit
    private let evmBlockchainManager = App.shared.evmBlockchainManager

    init(kit: OneInchKit.Kit, storage: MultiSwapSettingStorage) {
        self.kit = kit
        self.storage = storage
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
}

extension OneInchMultiSwapProvider: IMultiSwapProvider {
    var id: String {
        "1inch"
    }

    var name: String {
        "1Inch"
    }

    var icon: String {
        "1inch_32"
    }

    func supports(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Bool {
        guard tokenIn.blockchainType == tokenOut.blockchainType else {
            return false
        }

        switch tokenIn.blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom: return true
        default: return false
        }
    }

    func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> MultiSwapQuote {
        let blockchainType = tokenIn.blockchainType
        let chain = evmBlockchainManager.chain(blockchainType: blockchainType)

        let addressFrom = try address(token: tokenIn)
        let addressTo = try address(token: tokenOut)

        guard let amount = rawAmount(amount: amountIn, token: tokenIn) else {
            throw SwapError.invalidAmountIn
        }

        let gasPrice: GasPrice
        if chain.isEIP1559Supported {
            gasPrice = .eip1559(maxFeePerGas: 25_000_000_000, maxPriorityFeePerGas: 1_000_000_000)
        } else {
            gasPrice = .legacy(gasPrice: 3_000_000_000)
        }

        let quote = try await kit.quote(
            chain: chain,
            fromToken: addressFrom,
            toToken: addressTo,
            amount: amount,
            gasPrice: gasPrice
        )

        guard let amountOut = quote.amountOut else {
            throw SwapError.invalidAmountOut
        }

        var fee: MultiSwapQuote.TokenAmount?

        do {
            guard let feeToken = try marketKit.token(query: TokenQuery(blockchainType: tokenIn.blockchainType, tokenType: .native)) else {
                throw FeeError.noFeeToken
            }

            guard let amount = Decimal(bigUInt: BigUInt(quote.estimateGas) * BigUInt(gasPrice.max), decimals: feeToken.decimals) else {
                throw FeeError.invalidAmount
            }

            fee = MultiSwapQuote.TokenAmount(token: feeToken, amount: amount)
        } catch {
            print("Fee Error: \(error)")
        }

        var fields = [MultiSwapQuote.Field]()

        fields.append(
            MultiSwapQuote.Field(
                title: "Network Fee",
                memo: .init(title: "Network Fee", text: "Network Fee description"),
                value: "$0.98",
                settingId: "network_fee"
            )
        )

        fields.append(
            MultiSwapQuote.Field(
                title: "Slippage",
                value: "3%",
                valueLevel: .warning
            )
        )

        return MultiSwapQuote(amountOut: amountOut, fee: fee, fields: fields)
    }

    func view(settingId: String) -> AnyView {
        switch settingId {
        case "network_fee": AnyView(Text("Network Fee"))
        default: AnyView(EmptyView())
        }
    }
}

extension OneInchMultiSwapProvider {
    enum SwapError: Error {
        case invalidAddress
        case invalidAmountIn
        case invalidAmountOut
    }

    enum FeeError: Error {
        case noFeeToken
        case invalidAmount
    }
}
