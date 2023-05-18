import Foundation
import UniswapKit
import EvmKit
import MarketKit

class UniswapV3Provider {
    private let swapKit: UniswapKit.KitV3

    init(swapKit: UniswapKit.KitV3) {
        self.swapKit = swapKit
    }

    private func uniswapToken(token: MarketKit.Token) throws -> UniswapKit.Token {
        switch token.type {
        case .native: return swapKit.etherToken
        case let .eip20(address): return swapKit.token(contractAddress: try EvmKit.Address(hex: address), decimals: token.decimals)
        default: throw TokenError.unsupportedToken
        }
    }

}

extension UniswapV3Provider {

    var routerAddress: EvmKit.Address {
        swapKit.routerAddress
    }

    var wethAddress: EvmKit.Address {
        swapKit.etherToken.address
    }

    func bestTrade(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amount: Decimal, tradeType: TradeType, tradeOptions: TradeOptions) async throws -> TradeDataV3 {
        let uniswapTokenIn = try uniswapToken(token: tokenIn)
        let uniswapTokenOut = try uniswapToken(token: tokenOut)

        switch tradeType {
        case .exactIn:
            return try await swapKit.bestTradeExactIn(tokenIn: uniswapTokenIn, tokenOut: uniswapTokenOut, amountIn: amount, options: tradeOptions)
        case .exactOut:
            return try await swapKit.bestTradeExactOut(tokenIn: uniswapTokenIn, tokenOut: uniswapTokenOut, amountOut: amount, options: tradeOptions)
        }
    }

    func transactionData(tradeData: TradeDataV3, tradeOptions: TradeOptions) throws -> TransactionData {
        try swapKit.transactionData(bestTrade: tradeData, tradeOptions: tradeOptions)
    }

}

extension UniswapV3Provider {

    enum TokenError: Error {
        case unsupportedToken
    }

}
