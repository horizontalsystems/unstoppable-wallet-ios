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
    private let networkManager = NetworkManager()

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

        guard let rpcSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)?.rpcSource else {
            throw SwapError.notSupportedBlockchainType
        }

        let gasPrice: GasPrice
        if chain.isEIP1559Supported {
            gasPrice = try await EIP1559GasPriceProvider.gasPrice(networkManager: networkManager, rpcSource: rpcSource)
        } else {
            gasPrice = try await LegacyGasPriceProvider.gasPrice(networkManager: networkManager, rpcSource: rpcSource)
        }

        let quote = try await kit.quote(
            networkManager: networkManager,
            chain: chain,
            fromToken: addressFrom,
            toToken: addressTo,
            amount: amount,
            gasPrice: gasPrice
        )

        return try Quote(
            quote: quote,
            tokenOut: tokenOut,
            feeToken: marketKit.token(query: TokenQuery(blockchainType: tokenIn.blockchainType, tokenType: .native)),
            gasPrice: gasPrice,
            slippage: 2.5
        )
    }

    func settingsView() -> AnyView {
        let view = ThemeNavigationView { Text("1Inch Settings View") }
        return AnyView(view)
    }

    func settingView(settingId: String) -> AnyView {
        switch settingId {
        case "network_fee": return AnyView(ThemeNavigationView { EvmFeeSettingsModule.view() })
        default: return AnyView(EmptyView())
        }
    }
}

extension OneInchMultiSwapProvider {
    enum SwapError: Error {
        case invalidAddress
        case invalidAmountIn
        case invalidAmountOut
        case notSupportedBlockchainType
    }
}

extension OneInchMultiSwapProvider {
    struct Quote: IMultiSwapQuote {
        private let quote: OneInchKit.Quote
        private let tokenOut: MarketKit.Token
        private let feeToken: MarketKit.Token?
        private let gasPrice: GasPrice?
        private let slippage: Decimal

        init(quote: OneInchKit.Quote, tokenOut: MarketKit.Token, feeToken: MarketKit.Token?, gasPrice: GasPrice?, slippage: Decimal) {
            self.quote = quote
            self.tokenOut = tokenOut
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

        var confirmFieldSections: [[MultiSwapConfirmField]] {
            var sections = [[MultiSwapConfirmField]]()

            let minAmountOut = amountOut * (1 - slippage / 100)

            sections.append(
                [
                    .value(
                        title: "Minimum Received",
                        memo: nil,
                        coinValue: CoinValue(kind: .token(token: tokenOut), value: minAmountOut),
                        currencyValue: nil
                    ),
                ]
            )

            if let fee {
                sections.append(
                    [
                        .value(
                            title: "Network Fee",
                            memo: .init(title: "Network Fee", text: "Network Fee description"),
                            coinValue: fee,
                            currencyValue: nil
                        ),
                    ]
                )
            }

            return sections
        }

        var settingsModified: Bool {
            true
        }
    }
}
