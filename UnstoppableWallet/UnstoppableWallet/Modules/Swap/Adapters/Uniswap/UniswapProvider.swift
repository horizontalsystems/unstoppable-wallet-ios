import UniswapKit
import RxSwift
import EthereumKit
import Foundation
import MarketKit

class UniswapProvider {
    private let swapKit: UniswapKit.Kit

    init(swapKit: UniswapKit.Kit) {
        self.swapKit = swapKit
    }

    private func uniswapToken(platformCoin: PlatformCoin) throws -> Token {
        if case let .erc20(address) = platformCoin.coinType {
            return swapKit.token(contractAddress: try EthereumKit.Address(hex: address), decimals: platformCoin.decimals)
        } else if case let .bep20(address) = platformCoin.coinType {
            return swapKit.token(contractAddress: try EthereumKit.Address(hex: address), decimals: platformCoin.decimals)
        }

        return swapKit.etherToken
    }

}

extension UniswapProvider {

    var routerAddress: EthereumKit.Address {
        swapKit.routerAddress
    }

    func swapDataSingle(platformCoinIn: PlatformCoin, platformCoinOut: PlatformCoin) -> Single<SwapData> {
        do {
            let tokenIn = try uniswapToken(platformCoin: platformCoinIn)
            let tokenOut = try uniswapToken(platformCoin: platformCoinOut)

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
