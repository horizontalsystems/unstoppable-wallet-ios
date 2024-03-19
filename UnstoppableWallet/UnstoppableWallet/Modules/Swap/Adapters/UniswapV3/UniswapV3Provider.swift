import EvmKit
import Foundation
import MarketKit
import UniswapKit

class UniswapV3Provider {
    private let swapKit: UniswapKit.KitV3
    private let evmKit: EvmKit.Kit
    private let rpcSource: RpcSource

    init(swapKit: UniswapKit.KitV3, evmKit: EvmKit.Kit, rpcSource: RpcSource) {
        self.swapKit = swapKit
        self.evmKit = evmKit
        self.rpcSource = rpcSource
    }

    private func uniswapToken(token: MarketKit.Token) throws -> UniswapKit.Token {
        switch token.type {
        case .native: return try swapKit.etherToken(chain: evmKit.chain)
        case let .eip20(address): return try swapKit.token(contractAddress: EvmKit.Address(hex: address), decimals: token.decimals)
        default: throw TokenError.unsupportedToken
        }
    }
}

extension UniswapV3Provider {
    var routerAddress: EvmKit.Address {
        swapKit.routerAddress(chain: evmKit.chain)
    }

    var wethAddress: EvmKit.Address {
        try! swapKit.etherToken(chain: evmKit.chain).address
    }

    func bestTrade(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amount: Decimal, tradeType: TradeType, tradeOptions: TradeOptions) async throws -> TradeDataV3 {
        let uniswapTokenIn = try uniswapToken(token: tokenIn)
        let uniswapTokenOut = try uniswapToken(token: tokenOut)

        switch tradeType {
        case .exactIn:
            return try await swapKit.bestTradeExactIn(rpcSource: rpcSource, chain: evmKit.chain, tokenIn: uniswapTokenIn, tokenOut: uniswapTokenOut, amountIn: amount, options: tradeOptions)
        case .exactOut:
            return try await swapKit.bestTradeExactOut(rpcSource: rpcSource, chain: evmKit.chain, tokenIn: uniswapTokenIn, tokenOut: uniswapTokenOut, amountOut: amount, options: tradeOptions)
        }
    }

    func transactionData(tradeData: TradeDataV3, tradeOptions: TradeOptions) throws -> TransactionData {
        try swapKit.transactionData(receiveAddress: evmKit.receiveAddress, chain: evmKit.chain, bestTrade: tradeData, tradeOptions: tradeOptions)
    }
}

extension UniswapV3Provider {
    enum TokenError: Error {
        case unsupportedToken
    }
}
