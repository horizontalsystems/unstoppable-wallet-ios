import Foundation
import EthereumKit
import Erc20Kit
import UniswapKit
import OneInchKit
import CoinKit
import BigInt

class EvmTransactionConverter {
    private let coinManager: ICoinManager
    private let evmKit: EthereumKit.Kit
    private let baseCoin: Coin

    init(coinManager: ICoinManager, evmKit: EthereumKit.Kit) {
        self.coinManager = coinManager
        self.evmKit = evmKit

        switch evmKit.networkType {
        case .bscMainNet: baseCoin = coinManager.coinOrStub(type: .binanceSmartChain)
        default: baseCoin = coinManager.coinOrStub(type: .ethereum)
        }
    }

    private func convertAmount(amount: BigUInt, decimal: Int, sign: FloatingPointSign) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        return Decimal(sign: sign, exponent: -decimal, significand: significand)
    }

    private func eip20Coin(tokenAddress: EthereumKit.Address) -> Coin {
        let coinType: CoinType

        switch evmKit.networkType {
        case .bscMainNet: coinType = .bep20(address: tokenAddress.hex)
        default: coinType = .erc20(address: tokenAddress.hex)
        }

        return coinManager.coinOrStub(type: coinType)
    }

    private func convertToCoin(token: SwapMethodDecoration.Token) -> Coin {
        switch token {
        case .evmCoin:
            return baseCoin

        case .eip20Coin(let tokenAddress):
            switch evmKit.networkType {
            case .bscMainNet: return coinManager.coinOrStub(type: .bep20(address: tokenAddress.hex))
            default: return coinManager.coinOrStub(type: .erc20(address: tokenAddress.hex))
            }
        }
    }

    private func convertToCoin(token: OneInchMethodDecoration.Token) -> Coin {
        switch token {
        case .evmCoin:
            return baseCoin

        case .eip20Coin(let tokenAddress):
            switch evmKit.networkType {
            case .bscMainNet: return coinManager.coinOrStub(type: .bep20(address: tokenAddress.hex))
            default: return coinManager.coinOrStub(type: .erc20(address: tokenAddress.hex))
            }
        }
    }

    private func convertMyCall(methodDecoration: ContractMethodDecoration, fullTransaction: FullTransaction, to: EthereumKit.Address) -> EvmTransactionRecord {
        switch methodDecoration {
        case let decoration as TransferMethodDecoration:
            let token = eip20Coin(tokenAddress: to)

            return EvmOutgoingTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    amount: convertAmount(amount: decoration.value, decimal: token.decimal, sign: .minus),
                    to: decoration.to.eip55,
                    token: token,
                    sentToSelf: decoration.to == fullTransaction.transaction.from
            )

        case let decoration as ApproveMethodDecoration:
            let token = eip20Coin(tokenAddress: to)

            return ApproveTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    amount: convertAmount(amount: decoration.value, decimal: token.decimal, sign: .plus),
                    spender: decoration.spender.eip55,
                    token: token
            )

        case let decoration as SwapMethodDecoration:
            let resolvedAmountIn: BigUInt
            let resolvedAmountOut: BigUInt

            switch decoration.trade {
            case .exactIn(let amountIn, let amountOutMin, let amountOut):
                resolvedAmountIn = amountIn
                resolvedAmountOut = amountOut ?? amountOutMin

            case .exactOut(let amountOut, let amountInMax, let amountIn):
                resolvedAmountIn = amountIn ?? amountInMax
                resolvedAmountOut = amountOut
            }

            let tokenIn = convertToCoin(token: decoration.tokenIn)
            let tokenOut = convertToCoin(token: decoration.tokenOut)

            return SwapTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    exchangeAddress: to.eip55,
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: convertAmount(amount: resolvedAmountIn, decimal: tokenIn.decimal, sign: .minus),
                    amountOut: decoration.to == evmKit.address ? convertAmount(amount: resolvedAmountOut, decimal: tokenOut.decimal, sign: .plus) : nil
            )

        case let decoration as OneInchUnoswapMethodDecoration:
            let tokenIn = convertToCoin(token: decoration.tokenIn)
            let tokenOut = decoration.tokenOut.flatMap { convertToCoin(token: $0) }

            return SwapTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    exchangeAddress: to.eip55,
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: convertAmount(amount: decoration.amountIn, decimal: tokenIn.decimal, sign: .minus),
                    amountOut: tokenOut.flatMap { convertAmount(amount: decoration.amountOut, decimal: $0.decimal, sign: .plus) }
            )

        case let decoration as OneInchSwapMethodDecoration:
            let tokenIn = convertToCoin(token: decoration.tokenIn)
            let tokenOut = convertToCoin(token: decoration.tokenOut)

            return SwapTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    exchangeAddress: to.eip55,
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    amountIn: convertAmount(amount: decoration.amountIn, decimal: tokenIn.decimal, sign: .minus),
                    amountOut: decoration.recipient == evmKit.address ? convertAmount(amount: decoration.amountOut, decimal: tokenOut.decimal, sign: .plus) : nil
            )

        case let decoration as RecognizedMethodDecoration:
            return ContractCallTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    contractAddress: to.eip55,
                    method: decoration.method
            )

        case let decoration as UnknownMethodDecoration:
            return ContractCallTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    contractAddress: to.eip55,
                    method: nil
            )

        default:
            return EvmTransactionRecord(fullTransaction: fullTransaction, baseCoin: baseCoin)
        }
    }

    private func convertForeignCall(methodDecoration: ContractMethodDecoration, fullTransaction: FullTransaction, to: EthereumKit.Address) -> EvmTransactionRecord {
        switch methodDecoration {
        case let decoration as TransferMethodDecoration:
            if decoration.to == evmKit.address {
                let token = eip20Coin(tokenAddress: to)

                return EvmIncomingTransactionRecord(
                        fullTransaction: fullTransaction,
                        baseCoin: baseCoin,
                        amount: convertAmount(amount: decoration.value, decimal: token.decimal, sign: .plus),
                        from: decoration.to.eip55,
                        token: token
                )
            }

        case let decoration as RecognizedMethodDecoration:
            return ContractCallTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    contractAddress: to.eip55,
                    method: decoration.method
            )

        case is UnknownMethodDecoration:
            return ContractCallTransactionRecord(
                    fullTransaction: fullTransaction,
                    baseCoin: baseCoin,
                    contractAddress: to.eip55,
                    method: nil
            )

        default: ()
        }

        return EvmTransactionRecord(fullTransaction: fullTransaction, baseCoin: baseCoin)
    }

}

extension EvmTransactionConverter {

    func transactionRecord(fromTransaction fullTransaction: FullTransaction) -> EvmTransactionRecord {
        let transaction = fullTransaction.transaction

        guard let to = transaction.to else {
            return ContractCreationTransactionRecord(fullTransaction: fullTransaction, baseCoin: baseCoin)
        }

        let record: EvmTransactionRecord

        if let methodDecoration = fullTransaction.mainDecoration {
            if fullTransaction.transaction.from == evmKit.address {
                record = convertMyCall(methodDecoration: methodDecoration, fullTransaction: fullTransaction, to: to)
            } else {
                record = convertForeignCall(methodDecoration: methodDecoration, fullTransaction: fullTransaction, to: to)
            }
        } else {
            if transaction.from == evmKit.address {
                record = EvmOutgoingTransactionRecord(
                        fullTransaction: fullTransaction,
                        baseCoin: baseCoin,
                        amount: convertAmount(amount: transaction.value, decimal: baseCoin.decimal, sign: .minus),
                        to: to.eip55,
                        token: baseCoin,
                        sentToSelf: to == transaction.from
                )
            } else if to == evmKit.address {
                record = EvmIncomingTransactionRecord(
                        fullTransaction: fullTransaction,
                        baseCoin: baseCoin,
                        amount: convertAmount(amount: transaction.value, decimal: baseCoin.decimal, sign: .plus),
                        from: transaction.from.eip55,
                        token: baseCoin
                )
            } else {
                record = EvmTransactionRecord(fullTransaction: fullTransaction, baseCoin: baseCoin)
            }
        }

        if record is ContractCallTransactionRecord {
            for internalTransaction in fullTransaction.internalTransactions {
                if internalTransaction.to == evmKit.address {
                    let amount = convertAmount(amount: internalTransaction.value, decimal: baseCoin.decimal, sign: .plus)
                    record.incomingInternalETHs.append((from: internalTransaction.from.eip55, value: CoinValue(coin: baseCoin, value: amount)))
                }
            }

            for event in fullTransaction.eventDecorations {
                if let decoration = event as? TransferEventDecoration {
                    let token = eip20Coin(tokenAddress: decoration.contractAddress)

                    if decoration.from == evmKit.address {
                        let amount = convertAmount(amount: decoration.value, decimal: token.decimal, sign: .minus)

                        record.outgoingEip20Events.append((to: decoration.to.eip55, value: CoinValue(coin: token, value: amount)))
                    } else if decoration.to == evmKit.address {
                        let amount = convertAmount(amount: decoration.value, decimal: token.decimal, sign: .plus)

                        record.incomingEip20Events.append((from: decoration.from.eip55, value: CoinValue(coin: token, value: amount)))
                    }
                }
            }
        }

        return record
    }

}
