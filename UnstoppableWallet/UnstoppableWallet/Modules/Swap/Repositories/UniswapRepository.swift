import UniswapKit
import RxSwift
import EthereumKit
import Foundation

class UniswapRepository {
    private let swapKit: UniswapKit.Kit

    private var swapData = [String: SwapData]()

    init(swapKit: UniswapKit.Kit) {
        self.swapKit = swapKit
    }

    private func uniswapToken(coin: Coin) throws -> Token {
        if case let .erc20(address, _, _, _) = coin.type {
            return swapKit.token(contractAddress: try Address(hex: address), decimals: coin.decimal)
        }

        return swapKit.etherToken
    }

    private func uniqueCoinId(coinIn: Coin, coinOut: Coin) -> String {
        [coinIn.code, coinOut.code].joined(separator: "_")
    }

    private func save(swapData: SwapData, coinIn: Coin, coinOut: Coin) {
        self.swapData[self.uniqueCoinId(coinIn: coinIn, coinOut: coinOut)] = swapData
    }

    private func swapData(coinIn: Coin, coinOut: Coin) -> Single<SwapData> {
        do {
            let tokenIn = try uniswapToken(coin: coinIn)
            let tokenOut = try uniswapToken(coin: coinOut)

            if let swapData = swapData[uniqueCoinId(coinIn: coinIn, coinOut: coinOut)] {
                return Single.just(swapData)
            }

            return swapKit.swapDataSingle(tokenIn: tokenIn, tokenOut: tokenOut)
                    .do(onSuccess: { [weak self] swapData in
                        self?.save(swapData: swapData, coinIn: coinIn, coinOut: coinOut)
                    })
        } catch {
            return Single.error(error)
        }
    }

    private func tradeData(swapData: SwapData, amount: Decimal, tradeType: TradeType, tradeOptions: TradeOptions) -> Single<TradeData> {
        do {
            let tradeData: TradeData
            switch tradeType {
            case .exactIn:
                tradeData = try swapKit.bestTradeExactIn(swapData: swapData, amountIn: amount, options: tradeOptions)
            case .exactOut:
                tradeData = try swapKit.bestTradeExactOut(swapData: swapData, amountOut: amount, options: tradeOptions)
            }

            return Single.just(tradeData)
        } catch {
            return Single.error(error)
        }
    }

}

extension UniswapRepository {

    var routerAddress: Address {
        swapKit.routerAddress
    }

    func trade(coinIn: Coin, coinOut: Coin, amount: Decimal, tradeType: TradeType, tradeOptions: TradeOptions) -> Single<TradeData> {
        swapData(coinIn: coinIn, coinOut: coinOut).flatMap { [weak self] swapData in
            guard let data = self?.tradeData(swapData: swapData, amount: amount, tradeType: tradeType, tradeOptions: tradeOptions) else {
                return Single.error(AppError.unknownError)
            }
            return data
        }
    }

    func swap(tradeData: TradeData, gasLimit: Int, gasPrice: Int) -> Single<TransactionWithInternal> {
//        swapKit.swapSingle(tradeData: tradeData, gasLimit: gasLimit, gasPrice: gasPrice)
        Single.error(AppError.unknownError)
    }

    func transactionData(tradeData: TradeData) throws -> TransactionData {
        try swapKit.transactionData(tradeData: tradeData)
    }

}
