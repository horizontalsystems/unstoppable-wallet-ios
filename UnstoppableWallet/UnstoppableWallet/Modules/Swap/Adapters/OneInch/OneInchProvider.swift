import OneInchKit
import RxSwift
import EthereumKit
import Foundation
import MarketKit
import BigInt

class OneInchProvider {
    private let swapKit: OneInchKit.Kit

    init(swapKit: OneInchKit.Kit) {
        self.swapKit = swapKit
    }

    private func units(amount: Decimal, platformCoin: PlatformCoin) -> BigUInt? {
        let amountUnitString = (amount * pow(10, platformCoin.decimals)).roundedString(decimal: 0)
        return BigUInt(amountUnitString)
    }

    private func address(platformCoin: PlatformCoin) throws -> EthereumKit.Address {
        switch platformCoin.coinType {
        case .ethereum, .binanceSmartChain, .polygon: return try EthereumKit.Address(hex: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
        case .erc20(let address): return try EthereumKit.Address(hex: address)
        case .bep20(let address): return try EthereumKit.Address(hex: address)
        case .mrc20(let address): return try EthereumKit.Address(hex: address)
        default: throw SwapError.invalidAddress
        }
    }

}

extension OneInchProvider {

    var routerAddress: EthereumKit.Address {
        swapKit.routerAddress
    }

    func quoteSingle(platformCoinIn: PlatformCoin, platformCoinOut: PlatformCoin, amount: Decimal) -> Single<OneInchKit.Quote> {
        guard let amountUnits = units(amount: amount, platformCoin: platformCoinIn) else {
            return Single.error(SwapError.insufficientAmount)
        }

        do {
            let addressFrom = try address(platformCoin: platformCoinIn)
            let addressTo = try address(platformCoin: platformCoinOut)

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

    func swapSingle(platformCoinFrom: PlatformCoin, platformCoinTo: PlatformCoin, amount: Decimal, recipient: EthereumKit.Address?, slippage: Decimal, gasPrice: GasPrice?) -> Single<OneInchKit.Swap> {
        guard let amountUnits = units(amount: amount, platformCoin: platformCoinFrom) else {
            return Single.error(SwapError.insufficientAmount)
        }

        do {
            let addressFrom = try address(platformCoin: platformCoinFrom)
            let addressTo = try address(platformCoin: platformCoinTo)

            return swapKit.swapSingle(fromToken: addressFrom,
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
