import UniswapKit
import RxSwift
import EvmKit
import Foundation
import MarketKit

class UniswapProvider {
    private let swapKit: UniswapKit.Kit

    init(swapKit: UniswapKit.Kit) {
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

extension UniswapProvider {

    var routerAddress: EvmKit.Address {
        swapKit.routerAddress
    }

    func swapDataSingle(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token) -> Single<SwapData> {
        do {
            let uniswapTokenIn = try uniswapToken(token: tokenIn)
            let uniswapTokenOut = try uniswapToken(token: tokenOut)

            return swapKit.swapDataSingle(tokenIn: uniswapTokenIn, tokenOut: uniswapTokenOut)
        } catch {
            return Single.error(error)
        }
    }

    func tradeData(swapData: SwapData, amount: Decimal, tradeType: TradeType, tradeOptions: TradeOptions) throws -> TradeData {
        switch tradeType {
        case .exactIn:
            return try swapKit.bestTradeExactIn(swapData: swapData, amountIn: amount, options: tradeOptions)
        case .exactOut:
            return try swapKit.bestTradeExactOut(swapData: swapData, amountOut: amount, options: tradeOptions)
        }
    }

    func transactionData(tradeData: TradeData) throws -> TransactionData {
        try swapKit.transactionData(tradeData: tradeData)
    }

}

extension UniswapProvider {

    enum TokenError: Error {
        case unsupportedToken
    }

}
