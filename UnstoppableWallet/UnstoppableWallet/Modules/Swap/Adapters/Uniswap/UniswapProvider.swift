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
        switch platformCoin.coinType {
        case .ethereum, .binanceSmartChain, .polygon: return swapKit.etherToken
        case let .erc20(address): return swapKit.token(contractAddress: try EthereumKit.Address(hex: address), decimals: platformCoin.decimals)
        case let .bep20(address): return swapKit.token(contractAddress: try EthereumKit.Address(hex: address), decimals: platformCoin.decimals)
        case let .mrc20(address): return swapKit.token(contractAddress: try EthereumKit.Address(hex: address), decimals: platformCoin.decimals)
        default: throw TokenError.unsupportedPlatformCoinType
        }
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

extension UniswapProvider {

    enum TokenError: Error {
        case unsupportedPlatformCoinType
    }

}
