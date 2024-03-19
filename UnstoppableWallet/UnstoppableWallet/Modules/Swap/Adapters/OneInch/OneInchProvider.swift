import BigInt
import EvmKit
import Foundation
import HsExtensions
import HsToolKit
import MarketKit
import OneInchKit
import RxSwift

class OneInchProvider {
    private let swapKit: OneInchKit.Kit
    private let evmKit: EvmKit.Kit
    private let rpcSource: RpcSource
    private let networkManager = NetworkManager()

    init(swapKit: OneInchKit.Kit, evmKit: EvmKit.Kit, rpcSource: RpcSource) {
        self.swapKit = swapKit
        self.evmKit = evmKit
        self.rpcSource = rpcSource
    }

    private func units(amount: Decimal, token: MarketKit.Token) -> BigUInt? {
        let amountUnitString = (amount * pow(10, token.decimals)).hs.roundedString(decimal: 0)
        return BigUInt(amountUnitString)
    }

    private func address(token: MarketKit.Token) throws -> EvmKit.Address {
        switch token.type {
        case .native: return try EvmKit.Address(hex: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
        case let .eip20(address): return try EvmKit.Address(hex: address)
        default: throw SwapError.invalidAddress
        }
    }
}

extension OneInchProvider {
    var routerAddress: EvmKit.Address {
        try! OneInchKit.Kit.routerAddress(chain: evmKit.chain)
    }

    func quoteSingle(tokenIn: MarketKit.Token, tokenOut: MarketKit.Token, amount: Decimal) -> Single<OneInchKit.Quote> {
        guard let amountUnits = units(amount: amount, token: tokenIn) else {
            return Single.error(SwapError.insufficientAmount)
        }

        do {
            let addressFrom = try address(token: tokenIn)
            let addressTo = try address(token: tokenOut)

            return swapKit.quoteSingle(
                networkManager: networkManager,
                chain: evmKit.chain,
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
                networkManager: networkManager,
                chain: evmKit.chain,
                receiveAddress: evmKit.receiveAddress,
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
