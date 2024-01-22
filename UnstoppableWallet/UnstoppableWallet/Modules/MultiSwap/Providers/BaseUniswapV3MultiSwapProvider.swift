import BigInt
import EvmKit
import Foundation
import MarketKit
import UniswapKit

class BaseUniswapV3MultiSwapProvider {
    static let defaultSlippage: Decimal = 1

    private let kit: UniswapKit.KitV3
    private let marketKit = App.shared.marketKit
    private let evmBlockchainManager = App.shared.evmBlockchainManager
    private let evmSyncSourceManager = App.shared.evmSyncSourceManager

    init(kit: UniswapKit.KitV3) {
        self.kit = kit
    }

    private func kitToken(chain: Chain, token: MarketKit.Token) throws -> UniswapKit.Token {
        switch token.type {
        case .native: return try kit.etherToken(chain: chain)
        case let .eip20(address): return try kit.token(contractAddress: EvmKit.Address(hex: address), decimals: token.decimals)
        default: throw SwapError.invalidToken
        }
    }

    func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> IMultiSwapQuote {
        let blockchainType = tokenIn.blockchainType
        let chain = evmBlockchainManager.chain(blockchainType: blockchainType)

        let kitTokenIn = try kitToken(chain: chain, token: tokenIn)
        let kitTokenOut = try kitToken(chain: chain, token: tokenOut)
        let tradeOptions = TradeOptions()

        guard let rpcSource = evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)?.rpcSource else {
            throw SwapError.noHttpRpcSource
        }

        let bestTrade = try await kit.bestTradeExactIn(rpcSource: rpcSource, chain: chain, tokenIn: kitTokenIn, tokenOut: kitTokenOut, amountIn: amountIn, options: tradeOptions)

        var resolvedGasPrice: GasPrice?
        var estimatedGas: Int?

        if let evmKit = App.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit {
            do {
                let transactionData = try kit.transactionData(receiveAddress: evmKit.receiveAddress, chain: chain, bestTrade: bestTrade, tradeOptions: tradeOptions)

                let gasPrice: GasPrice
                if chain.isEIP1559Supported {
                    gasPrice = .eip1559(maxFeePerGas: 25_000_000_000, maxPriorityFeePerGas: 1_000_000_000)
                } else {
                    gasPrice = .legacy(gasPrice: 3_000_000_000)
                }

                resolvedGasPrice = gasPrice
                estimatedGas = try await evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)
            } catch {}
        }

        return try Quote(
            bestTrade: bestTrade,
            feeToken: marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: .native)),
            gasPrice: resolvedGasPrice,
            estimatedGas: estimatedGas,
            slippage: 1.5
        )
    }
}

extension BaseUniswapV3MultiSwapProvider {
    enum SwapError: Error {
        case invalidToken
        case noHttpRpcSource
    }
}

extension BaseUniswapV3MultiSwapProvider {
    struct Quote: IMultiSwapQuote {
        private let bestTrade: TradeDataV3
        private let feeToken: MarketKit.Token?
        private let gasPrice: GasPrice?
        private let estimatedGas: Int?
        private let slippage: Decimal

        init(bestTrade: TradeDataV3, feeToken: MarketKit.Token?, gasPrice: GasPrice?, estimatedGas: Int?, slippage: Decimal) {
            self.bestTrade = bestTrade
            self.feeToken = feeToken
            self.gasPrice = gasPrice
            self.estimatedGas = estimatedGas
            self.slippage = slippage
        }

        var amountOut: Decimal {
            bestTrade.amountOut ?? 0
        }

        var fee: CoinValue? {
            guard let feeToken, let gasPrice, let estimatedGas else {
                return nil
            }

            guard let amount = Decimal(bigUInt: BigUInt(estimatedGas) * BigUInt(gasPrice.max), decimals: feeToken.decimals) else {
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

            if slippage != BaseUniswapMultiSwapProvider.defaultSlippage {
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
            []
        }
    }
}
