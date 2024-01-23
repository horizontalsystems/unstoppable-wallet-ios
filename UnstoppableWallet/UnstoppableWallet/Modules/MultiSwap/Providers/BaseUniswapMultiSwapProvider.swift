import BigInt
import EvmKit
import Foundation
import MarketKit
import UniswapKit

class BaseUniswapMultiSwapProvider {
    static let defaultSlippage: Decimal = 1

    private let kit: UniswapKit.Kit
    private let marketKit = App.shared.marketKit
    private let evmBlockchainManager = App.shared.evmBlockchainManager
    private let evmSyncSourceManager = App.shared.evmSyncSourceManager

    init(kit: UniswapKit.Kit) {
        self.kit = kit
    }

    private func kitToken(chain: Chain, token: MarketKit.Token) throws -> UniswapKit.Token {
        switch token.type {
        case .native: return try kit.etherToken(chain: chain)
        case let .eip20(address): return try kit.token(contractAddress: EvmKit.Address(hex: address), decimals: token.decimals)
        default: throw SwapError.invalidToken
        }
    }

    func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal, feeData: MultiSwapFeeData?) async throws -> IMultiSwapQuote {
        let blockchainType = tokenIn.blockchainType
        let chain = evmBlockchainManager.chain(blockchainType: blockchainType)

        let kitTokenIn = try kitToken(chain: chain, token: tokenIn)
        let kitTokenOut = try kitToken(chain: chain, token: tokenOut)

        guard let rpcSource = evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)?.rpcSource else {
            throw SwapError.noHttpRpcSource
        }

        let swapData = try await kit.swapData(rpcSource: rpcSource, chain: chain, tokenIn: kitTokenIn, tokenOut: kitTokenOut)
        let tradeData = try kit.bestTradeExactIn(swapData: swapData, amountIn: amountIn)

        var estimatedGas: Int?

        if let evmKit = App.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit,
           let feeData, case let .evm(gasPrice) = feeData
        {
            do {
                let transactionData = try kit.transactionData(receiveAddress: evmKit.receiveAddress, chain: chain, tradeData: tradeData)
                estimatedGas = try await evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)
            } catch {}
        }

        return Quote(
            tradeData: tradeData,
            estimatedGas: estimatedGas,
            slippage: 1.5
        )
    }
}

extension BaseUniswapMultiSwapProvider {
    enum SwapError: Error {
        case invalidToken
        case noHttpRpcSource
    }
}

extension BaseUniswapMultiSwapProvider {
    struct Quote: IMultiSwapQuote {
        private let tradeData: TradeData
        private let estimatedGas: Int?
        private let slippage: Decimal

        init(tradeData: TradeData, estimatedGas: Int?, slippage: Decimal) {
            self.tradeData = tradeData
            self.estimatedGas = estimatedGas
            self.slippage = slippage
        }

        var amountOut: Decimal {
            tradeData.amountOut ?? 0
        }

        var feeQuote: MultiSwapFeeQuote? {
            guard let estimatedGas else {
                return nil
            }

            return .evm(gasLimit: estimatedGas)
        }

        var mainFields: [MultiSwapMainField] {
            var fields = [MultiSwapMainField]()

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

        var settingsModified: Bool {
            false
        }
    }
}
