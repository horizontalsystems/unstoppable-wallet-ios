import UniswapKit
import RxSwift
import EthereumKit
import Foundation
import CoinKit

class UniswapProvider {
    private let swapKit: UniswapKit.Kit

    init(swapKit: UniswapKit.Kit) {
        self.swapKit = swapKit
    }

    private func uniswapToken(coin: Coin) throws -> Token {
        if case let .erc20(address) = coin.type {
            return swapKit.token(contractAddress: try EthereumKit.Address(hex: address), decimals: coin.decimal)
        } else if case let .bep20(address) = coin.type {
            return swapKit.token(contractAddress: try EthereumKit.Address(hex: address), decimals: coin.decimal)
        }

        return swapKit.etherToken
    }

}

extension UniswapProvider {

    var routerAddress: EthereumKit.Address {
        swapKit.routerAddress
    }

    func swapDataSingle(coinIn: Coin, coinOut: Coin) -> Single<SwapData> {
        do {
            let tokenIn = try uniswapToken(coin: coinIn)
            let tokenOut = try uniswapToken(coin: coinOut)

            return swapKit.swapDataSingle(tokenIn: tokenIn, tokenOut: tokenOut)
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
