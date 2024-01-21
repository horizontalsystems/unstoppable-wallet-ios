import BigInt
import EvmKit
import Foundation
import MarketKit
import OneInchKit
import SwiftUI

struct OneInchMultiSwapProvider {
    static let defaultSlippage: Decimal = 1

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

    func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> IMultiSwapQuote {
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

        return try Quote(
            quote: quote,
            feeToken: marketKit.token(query: TokenQuery(blockchainType: tokenIn.blockchainType, tokenType: .native)),
            gasPrice: gasPrice,
            slippage: 2.5
        )
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
    }
}

extension OneInchMultiSwapProvider {
    struct Quote: IMultiSwapQuote {
        private let quote: OneInchKit.Quote
        private let feeToken: MarketKit.Token?
        private let gasPrice: GasPrice?
        private let slippage: Decimal

        init(quote: OneInchKit.Quote, feeToken: MarketKit.Token?, gasPrice: GasPrice?, slippage: Decimal) {
            self.quote = quote
            self.feeToken = feeToken
            self.gasPrice = gasPrice
            self.slippage = slippage
        }

        var amountOut: Decimal {
            quote.amountOut ?? 0
        }

        var fee: CoinValue? {
            guard let feeToken, let gasPrice else {
                return nil
            }

            guard let amount = Decimal(bigUInt: BigUInt(quote.estimateGas) * BigUInt(gasPrice.max), decimals: feeToken.decimals) else {
                return nil
            }

            return CoinValue(kind: .token(token: feeToken), value: amount)
        }

        var mainFields: [MultiSwapMainField] {
            var fields = [MultiSwapMainField]()

            if let fee, let formatted = ValueFormatter.instance.formatShort(coinValue: fee) {
                fields.append(
                    MultiSwapMainField(
                        title: "Network Fee",
                        memo: .init(title: "Network Fee", text: "Network Fee description"),
                        value: formatted,
                        settingId: "network_fee"
                    )
                )
            }

            if slippage != OneInchMultiSwapProvider.defaultSlippage {
                fields.append(
                    MultiSwapMainField(
                        title: "Slippage",
                        value: "\(slippage.description)%",
                        valueLevel: .warning
                    )
                )
            }

            return fields
        }
    }
}
