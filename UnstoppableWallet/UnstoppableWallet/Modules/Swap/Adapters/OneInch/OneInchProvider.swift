import Foundation
import OneInchKit
import RxSwift
import EvmKit
import Foundation
import MarketKit
import BigInt
import HsExtensions

class OneInchProvider {
    private let swapKit: OneInchKit.Kit

    init(swapKit: OneInchKit.Kit) {
        self.swapKit = swapKit
    }

    private func units(amount: Decimal, token: MarketKit.Token) -> BigUInt? {
        let amountUnitString = (amount * pow(10, token.decimals)).hs.roundedString(decimal: 0)
        return BigUInt(amountUnitString)
    }

    private func address(token: MarketKit.Token) throws -> EvmKit.Address {
        switch token.type {
        case .native: return try EvmKit.Address(hex: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
        case .eip20(let address): return try EvmKit.Address(hex: address)
        default: throw SwapError.invalidAddress
        }
    }

}

extension OneInchProvider {

    var routerAddress: EvmKit.Address {
        swapKit.routerAddress
    }

    func quoteSingle(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amount: Decimal) -> Single<OneInchKit.Quote> {
        guard let amountUnits = units(amount: amount, token: tokenIn) else {
            return Single.error(SwapError.insufficientAmount)
        }

        do {
            let addressFrom = try address(token: tokenIn)
            let addressTo = try address(token: tokenOut)

            return swapKit.quoteSingle(
                    fromToken: addressFrom,
                    toToken: addressTo,
                    amount: amountUnits,
                    protocols: nil,
                    gasPrice: nil,
                    complexityLevel: nil,
                    connectorTokens: nil,
                    gasLimit: nil,
                    mainRouteParts: nil,
                    parts: nil
            )
        } catch {
            return Single.error(error)
        }
    }

    func swapSingle(tokenFrom: MarketKit.Token, tokenTo: MarketKit.Token, amount: Decimal, recipient: EvmKit.Address?, slippage: Decimal, gasPrice: GasPrice?) -> Single<OneInchKit.Swap> {
        guard let amountUnits = units(amount: amount, token: tokenFrom) else {
            return Single.error(SwapError.insufficientAmount)
        }

        do {
            let addressFrom = try address(token: tokenFrom)
            let addressTo = try address(token: tokenTo)

            return swapKit.swapSingle(
                    fromToken: addressFrom,
                    toToken: addressTo,
                    amount: amountUnits,
                    slippage: slippage,
                    protocols: nil,
                    recipient: recipient,
                    gasPrice: gasPrice,
                    burnChi: nil,
                    complexityLevel: nil,
                    connectorTokens: nil,
                    allowPartialFill: nil,
                    gasLimit: nil,
                    mainRouteParts: nil,
                    parts: nil
            )
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
