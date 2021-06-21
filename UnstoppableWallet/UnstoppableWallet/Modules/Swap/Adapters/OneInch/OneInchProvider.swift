import OneInchKit
import RxSwift
import EthereumKit
import Foundation
import CoinKit
import BigInt

class OneInchProvider {
    private let swapKit: OneInchKit.Kit

    init(swapKit: OneInchKit.Kit) {
        self.swapKit = swapKit
    }

    private func units(amount: Decimal, coin: Coin) -> BigUInt? {
        let amountUnitString = (amount * pow(10, coin.decimal)).roundedString(decimal: 0)
        return BigUInt(amountUnitString)
    }

    private func address(coin: Coin) throws -> EthereumKit.Address {
        if case let .erc20(address) = coin.type {
            return try EthereumKit.Address(hex: address)
        } else if case let .bep20(address) = coin.type {
            return try EthereumKit.Address(hex: address)
        }

        throw SwapError.invalidAddress
    }

}

extension OneInchProvider {

    var routerAddress: EthereumKit.Address {
        swapKit.routerAddress
    }

    func quoteSingle(coinIn: Coin, coinOut: Coin, amount: Decimal) -> Single<OneInchKit.Quote> {
        guard let amountUnits = units(amount: amount, coin: coinIn) else {
            return Single.error(SwapError.insufficientAmount)
        }

        do {
            let addressFrom = try address(coin: coinIn)
            let addressTo = try address(coin: coinOut)

            return swapKit.quoteSingle(fromToken: addressFrom,
                    toToken: addressTo,
                    amount: amountUnits,
                    protocols: nil,
                    gasPrice: nil,
                    complexityLevel: nil,
                    connectorTokens: nil,
                    gasLimit: nil,
                    mainRouteParts: nil,
                    parts: nil)
        } catch {
            return Single.error(error)
        }
    }

    func swapSingle(coinFrom: Coin, coinTo: Coin, amount: Decimal) -> Single<OneInchKit.Swap> {
        guard let amountUnits = units(amount: amount, coin: coinFrom) else {
            return Single.error(SwapError.insufficientAmount)
        }

        do {
            let addressFrom = try address(coin: coinFrom)
            let addressTo = try address(coin: coinTo)

            return swapKit.swapSingle(fromToken: addressFrom,
                    toToken: addressTo,
                    amount: amountUnits,
                    slippage: 0,
                    protocols: nil,
                    recipient: nil,
                    gasPrice: nil,
                    burnChi: nil,
                    complexityLevel: nil,
                    connectorTokens: nil,
                    allowPartialFill: nil,
                    gasLimit: nil,
                    mainRouteParts: nil,
                    parts: nil)
        } catch {
            return Single.error(error)
        }

    }

}

extension OneInchProvider {

    enum SwapError: Error {
        case invalidAddress
        case insufficientAmount
    }

}
