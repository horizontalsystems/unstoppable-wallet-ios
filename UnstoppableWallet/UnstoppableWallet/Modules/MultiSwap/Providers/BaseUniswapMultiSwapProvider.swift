import BigInt
import EvmKit
import Foundation
import MarketKit
import UniswapKit

class BaseUniswapMultiSwapProvider {
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

    func quote(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amountIn: Decimal) async throws -> MultiSwapQuote {
        let blockchainType = tokenIn.blockchainType
        let chain = evmBlockchainManager.chain(blockchainType: blockchainType)

        let kitTokenIn = try kitToken(chain: chain, token: tokenIn)
        let kitTokenOut = try kitToken(chain: chain, token: tokenOut)

        guard let rpcSource = evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)?.rpcSource else {
            throw SwapError.noHttpRpcSource
        }

        let swapData = try await kit.swapData(rpcSource: rpcSource, chain: chain, tokenIn: kitTokenIn, tokenOut: kitTokenOut)
        let tradeData = try kit.bestTradeExactIn(swapData: swapData, amountIn: amountIn)

        guard let amountOut = tradeData.amountOut else {
            throw SwapError.invalidAmountOut
        }

        var fee: MultiSwapQuote.TokenAmount?

        do {
            guard let feeToken = try marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: .native)) else {
                throw FeeError.noFeeToken
            }

            guard let evmKit = App.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper?.evmKit else {
                throw FeeError.noEvmKit
            }

            let transactionData = try kit.transactionData(receiveAddress: evmKit.receiveAddress, chain: chain, tradeData: tradeData)

            let gasPrice: GasPrice
            if chain.isEIP1559Supported {
                gasPrice = .eip1559(maxFeePerGas: 25_000_000_000, maxPriorityFeePerGas: 1_000_000_000)
            } else {
                gasPrice = .legacy(gasPrice: 3_000_000_000)
            }

            let gasLimit = try await evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)

            guard let amount = Decimal(bigUInt: BigUInt(gasLimit) * BigUInt(gasPrice.max), decimals: feeToken.decimals) else {
                throw FeeError.invalidAmount
            }

            fee = MultiSwapQuote.TokenAmount(token: feeToken, amount: amount)
        } catch {
            print("Fee Error: \(error)")
        }

        return MultiSwapQuote(amountOut: amountOut, fee: fee, fields: [])
    }
}

extension BaseUniswapMultiSwapProvider {
    enum SwapError: Error {
        case invalidToken
        case invalidAmountOut
        case noHttpRpcSource
    }

    enum FeeError: Error {
        case noFeeToken
        case noEvmKit
        case invalidAmount
    }
}
