import BigInt
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import OneInchKit
import SwiftUI

struct OneInchMultiSwapProvider {
    static let defaultSlippage: Decimal = 1

    private let kit: OneInchKit.Kit
    private let storage: MultiSwapSettingStorage
    private let marketKit = App.shared.marketKit
    private let evmBlockchainManager = App.shared.evmBlockchainManager
    private let networkManager = App.shared.networkManager

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

    func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal, feeData: MultiSwapFeeData?) async throws -> IMultiSwapQuote {
        let blockchainType = tokenIn.blockchainType
        let chain = evmBlockchainManager.chain(blockchainType: blockchainType)

        let addressFrom = try address(token: tokenIn)
        let addressTo = try address(token: tokenOut)

        guard let amount = rawAmount(amount: amountIn, token: tokenIn) else {
            throw SwapError.invalidAmountIn
        }

        guard let feeData, case let .evm(gasPrice) = feeData else {
            throw SwapError.noFeeData
        }

        let quote = try await kit.quote(
            networkManager: networkManager,
            chain: chain,
            fromToken: addressFrom,
            toToken: addressTo,
            amount: amount,
            gasPrice: gasPrice
        )

        return Quote(
            quote: quote,
            tokenOut: tokenOut,
            slippage: 2.5
        )
    }

    func settingsView() -> AnyView {
        let view = ThemeNavigationView {
            Text("1Inch Settings View")
        }
        return AnyView(view)
    }

    func settingView(settingId: String) -> AnyView {
        switch settingId {
        case "network_fee": return AnyView(ThemeNavigationView {
                EvmFeeSettingsModule.view()
            })
        default: return AnyView(EmptyView())
        }
    }
}

extension OneInchMultiSwapProvider {
    enum SwapError: Error {
        case invalidAddress
        case invalidAmountIn
        case noFeeData
    }
}

extension OneInchMultiSwapProvider {
    struct Quote: IMultiSwapQuote {
        private let quote: OneInchKit.Quote
        private let tokenOut: MarketKit.Token
        private let slippage: Decimal

        init(quote: OneInchKit.Quote, tokenOut: MarketKit.Token, slippage: Decimal) {
            self.quote = quote
            self.tokenOut = tokenOut
            self.slippage = slippage
        }

        var amountOut: Decimal {
            quote.amountOut ?? 0
        }

        var feeQuote: MultiSwapFeeQuote? {
            .evm(gasLimit: quote.estimateGas)
        }

        var mainFields: [MultiSwapMainField] {
            var fields = [MultiSwapMainField]()

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

        var confirmFieldSections: [[MultiSwapConfirmField]] {
            var sections = [[MultiSwapConfirmField]]()

            let minAmountOut = amountOut * (1 - slippage / 100)

            sections.append(
                [
                    .value(
                        title: "Minimum Received",
                        description: nil,
                        coinValue: CoinValue(kind: .token(token: tokenOut), value: minAmountOut),
                        currencyValue: nil
                    ),
                ]
            )

            return sections
        }

        var settingsModified: Bool {
            true
        }
    }
}
