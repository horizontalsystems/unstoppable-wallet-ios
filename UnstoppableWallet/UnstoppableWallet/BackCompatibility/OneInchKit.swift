import BigInt
import Combine
import EvmKit
import Foundation
import HsToolKit
import OneInchKit
import RxSwift

public extension OneInchKit.Kit {
    internal struct DisposedError: Error {}

    func quoteSingle(networkManager: NetworkManager,
                     chain: Chain,
                     fromToken: EvmKit.Address,
                     toToken: EvmKit.Address,
                     amount: BigUInt,
                     protocols: String? = nil,
                     gasPrice: GasPrice? = nil,
                     complexityLevel: Int? = nil,
                     connectorTokens: String? = nil,
                     gasLimit: Int? = nil,
                     mainRouteParts: Int? = nil,
                     parts: Int? = nil) -> Single<Quote>
    {
        Single<Quote>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.quote(
                        networkManager: networkManager,
                        chain: chain,
                        fromToken: fromToken,
                        toToken: toToken,
                        amount: amount,
                        protocols: protocols,
                        gasPrice: gasPrice,
                        complexityLevel: complexityLevel,
                        connectorTokens: connectorTokens,
                        gasLimit: gasLimit,
                        mainRouteParts: mainRouteParts,
                        parts: parts
                    )
                    observer(.success(result))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func swapSingle(networkManager: NetworkManager,
                    chain: Chain,
                    receiveAddress: EvmKit.Address,
                    fromToken: EvmKit.Address,
                    toToken: EvmKit.Address,
                    amount: BigUInt,
                    slippage: Decimal,
                    protocols: [String]? = nil,
                    recipient: EvmKit.Address? = nil,
                    gasPrice: GasPrice? = nil,
                    burnChi: Bool? = nil,
                    complexityLevel: Int? = nil,
                    connectorTokens: [String]? = nil,
                    allowPartialFill: Bool? = nil,
                    gasLimit: Int? = nil,
                    mainRouteParts: Int? = nil,
                    parts: Int? = nil) -> Single<Swap>
    {
        Single<Swap>.create { [weak self] observer in
            guard let strongSelf = self else {
                observer(.error(DisposedError()))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await strongSelf.swap(
                        networkManager: networkManager,
                        chain: chain,
                        receiveAddress: receiveAddress,
                        fromToken: fromToken,
                        toToken: toToken,
                        amount: amount,
                        slippage: slippage,
                        protocols: protocols,
                        recipient: recipient,
                        gasPrice: gasPrice,
                        burnChi: burnChi,
                        complexityLevel: complexityLevel,
                        connectorTokens: connectorTokens,
                        allowPartialFill: allowPartialFill,
                        gasLimit: gasLimit,
                        mainRouteParts: mainRouteParts,
                        parts: parts
                    )
                    observer(.success(result))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
}
